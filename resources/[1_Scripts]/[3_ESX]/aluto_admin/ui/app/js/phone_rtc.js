const RESOURCE_NAME = GetParentResourceName();

const constraints = {
    video: false,
    audio: true
}

const RTCConfig = {
    iceServers: [
        {
            urls: [
                'turn:162.19.72.25:3478',
            ],
            username: 'unityphone',
            credential: 'fun'
        },
    ]
};

let pc = null;
const pcCandidates = [];

let localStream = null;
let localGainNode = null;
let localMediaStreamDestinationNode = null;

let isTalking = false;
let isMuted = false;

const audio = new Audio();
const remoteStream = new MediaStream();

const canTalk = () => !isMuted && isTalking;

const enableLocalAudioTracks = (enabled) => {
    localStream.getAudioTracks().forEach((track) => {
        track.enabled = enabled;
    });
}

const onIceconnectionstatechange = (ev) => {
    //console.log('onIceconnectionstatechange', pc.iceConnectionState);
    if (pc.iceConnectionState === 'disconnected') { closeConnection(true); }
};

const onConnectionstatechange = (ev) => {
    //console.log('onConnectionstatechange', pc.onConnectionstatechange);
    if (pc.connectionState === 'disconnected') { closeConnection(true); }
};

const onSignalingstatechange = (ev) => {
    //console.log('onSignalingstatechange', pc.signalingState);
    if (pc.signalingState === 'closed') { closeConnection(true); }
};

const onIcegatheringstatechange = (ev) => {
    //console.log('onIcegatheringstatechange', pc.iceGatheringState)
    if (pc.iceGatheringState === 'complete') {
        const encodedCandidates = btoa(JSON.stringify(pcCandidates));
        $.post(`https://${RESOURCE_NAME}/phone_rtc:iceGatheringStateComplete`, JSON.stringify({ encodedCandidates: encodedCandidates }));
    }
}

const onicecandidate = (ev) => {
    if (!ev.candidate)
        return;

    //console.log('onicecandidate', ev.candidate);
    pcCandidates.push(ev.candidate);
}

const closeConnection = (forced) => {
    if (!pc)
        return;

    pc.removeEventListener('iceconnectionstatechange', onIceconnectionstatechange);
    pc.removeEventListener('connectionstatechange', onConnectionstatechange);
    pc.removeEventListener('signalingstatechange', onSignalingstatechange);

    pc.removeEventListener('icecandidate', onicecandidate);
    pc.removeEventListener('icegatheringstatechange', onIcegatheringstatechange);

    pc.close();
    pc = null;

    while (pcCandidates.length > 0) {
        pcCandidates.pop();
    }

    enableLocalAudioTracks(false);

    isTalking = false;
    isMuted = false;

    remoteStream.getTracks().forEach((track) => {
        track.stop();
        remoteStream.removeTrack(track);
    });

    if (forced) {
        $.post(`https://${RESOURCE_NAME}/phone_rtc:connectionClosed`);
    }
}

const newConnection = async () => {
    closeConnection();

    pc = new RTCPeerConnection(RTCConfig);

    if (!localStream) {
        localStream = await navigator.mediaDevices.getUserMedia(constraints);

        if (localStream) {
            const audioContext = new AudioContext();
            const mediaStreamSourceNode = audioContext.createMediaStreamSource(localStream);
            localMediaStreamDestinationNode = audioContext.createMediaStreamDestination();

            localGainNode = audioContext.createGain();
            mediaStreamSourceNode.connect(localGainNode);
            localGainNode.connect(localMediaStreamDestinationNode);

            localGainNode.gain.value = 1.0;
        }
    }

    enableLocalAudioTracks(canTalk());

    audio.srcObject = remoteStream;
    audio.load();

    const controlledStream = localMediaStreamDestinationNode.stream;

    controlledStream.getTracks().forEach((track) => {
        pc.addTrack(track, controlledStream);
    });

    pc.addEventListener('track', (ev) => {
        ev.streams[0].getTracks().forEach((track) => {
            remoteStream.addTrack(track);
        });
    });

    pc.addEventListener('iceconnectionstatechange', onIceconnectionstatechange);
    pc.addEventListener('connectionstatechange', onConnectionstatechange);
    pc.addEventListener('signalingstatechange', onSignalingstatechange);

    pc.addEventListener('icecandidate', onicecandidate);
    pc.addEventListener('icegatheringstatechange', onIcegatheringstatechange);
}

const createCallOffer = async () => {
    await newConnection();

    const offerDescription = await pc.createOffer();
    pc.setLocalDescription(offerDescription);

    return offerDescription;
}

const createCallAnswer = async (offer) => {
    await newConnection();

    const offerDescription = new RTCSessionDescription(offer);
    pc.setRemoteDescription(offerDescription);

    const answerDescription = await pc.createAnswer();
    pc.setLocalDescription(answerDescription);

    return answerDescription;
}

const receivedAnswer = async (answer) => {
    if (pc.currentRemoteDescription)
        return;

    const answerDescription = new RTCSessionDescription(answer);
    pc.setRemoteDescription(answerDescription);
}

window.addEventListener('load', e => {
    window.addEventListener('message', async (event) => {
        const data = event.data;

        switch (data.action) {
            case 'phone_rtc:createCallOffer': {
                const offerDescription = await createCallOffer();
                $.post(`https://${RESOURCE_NAME}/phone_rtc:createdCallOffer`, JSON.stringify({ encodedOffer: btoa(JSON.stringify(offerDescription)) }));
                break;
            }
            case 'phone_rtc:createCallAnswer': {
                const offer = JSON.parse(atob(data.encodedOffer));
                const answerDescription = await createCallAnswer(offer);
                $.post(`https://${RESOURCE_NAME}/phone_rtc:createdCallAnswer`, JSON.stringify({ encodedAnswer: btoa(JSON.stringify(answerDescription)) }));
                break;
            }
            case 'phone_rtc:receivedAnswer': {
                const answer = JSON.parse(atob(data.encodedAnswer));
                await receivedAnswer(answer);
                break;
            }
            case 'phone_rtc:addIceCandidates': {
                if (!pc)
                    return;

                const candidates = JSON.parse(atob(data.encodedCandidates));

                candidates.forEach((candidateData) => {
                    const candidate = new RTCIceCandidate(candidateData);
                    pc.addIceCandidate(candidate);
                });

                break;
            }
            case 'phone_rtc:addIceCandidate': {
                if (!pc)
                    return;

                const candidateData = JSON.parse(atob(data.encodedCandidate));
                const candidate = new RTCIceCandidate(candidateData);
                await pc.addIceCandidate(candidate);

                break;
            }
            case 'phone_rtc:toggleMute': {
                isMuted = !isMuted;

                if (!localStream)
                    return;

                enableLocalAudioTracks(canTalk());
                break;
            }
            case 'phone_rtc:setTalking': {
                isTalking = data.talking;

                if (!localStream)
                    return;

                enableLocalAudioTracks(canTalk());
                break;
            }
            case 'phone_rtc:closeConnection': {
                closeConnection();
                break;
            }
        }
    });
});