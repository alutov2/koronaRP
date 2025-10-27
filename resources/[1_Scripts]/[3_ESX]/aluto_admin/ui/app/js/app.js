(() => {
	const RESOURCE_NAME = GetParentResourceName();
	
	const frames = {};
	let focusedFrameName = null;
	const frameEscapeFunctions = {};

	const onFrameMessage = (name, data) => $.post(`https://${RESOURCE_NAME}/frame:${name}:message`, JSON.stringify(data));

	const showFrame = name => frames[name].style.display = 'block';
	const hideFrame = name => frames[name].style.display = 'none';
	const topFrame = name => frames[name].style.zIndex = '999999';

	const focusFrame = name => {
		if (focusedFrameName) {
			if (focusedFrameName === name)
				return;
	
			const focusedFrame = frames[focusedFrameName];

			if (focusedFrame) {
				focusedFrame.contentWindow.blur();
				focusedFrame.contentWindow.removeEventListener("blur", frameEscapeFunctions[focusedFrameName]);
				focusedFrame.style.pointerEvents = 'none';
			}
		}

		const frame = frames[name];
		focusedFrameName = name;

		frame.style.pointerEvents = 'all';

		// register blur event for unintentional tab escapes
		frame.contentWindow.addEventListener("blur", frameEscapeFunctions[name]);

		setTimeout(() => { frame.contentWindow.focus() }, 32);
	}

	const blurFrame = name => {
		const frame = frames[name];
		focusedFrameName = null;

		frame.contentWindow.blur();
		frame.contentWindow.removeEventListener("blur", frameEscapeFunctions[name]);
		frame.style.pointerEvents = 'none';
	}

	const createFrame = (name, url, visible = true) => {
		const frame = document.createElement('iframe');

		frame.name = name;
		frame.style.pointerEvents = 'none';
		frame.src = url;
		frame.tabIndex = -1;

		frames[name] = frame;

		document.querySelector('#frames').appendChild(frame);

		if (!visible)
			hideFrame(name);

		frame.contentWindow.addEventListener('message', e => {
			if (e.data.__internal !== true)
				onFrameMessage(name, e.data)
		});

		frame.contentWindow.addEventListener('DOMContentLoaded', () => {
			$.post(`https://${RESOURCE_NAME}/frame:${name}:load`);
		}, true);

		frameEscapeFunctions[name] = () => {
			setTimeout(() => {
				if (document.activeElement === document.body) {
					frame.contentWindow.focus();
				}
			}, 32);
		}

		frame.contentWindow.GetParentResourceName = () => RESOURCE_NAME;
		frame.contentWindow.GetFrameName = () => name;

		return frame;
	}

	const destroyFrame = name => {
		frames[name].remove();
		delete frames[name];
	}

	const onMessage = msg => {
		if (msg.target) {
			if (frames[msg.target]) {
				msg.data.__internal = true;
				frames[msg.target].contentWindow.postMessage(msg.data, '*');
			} else {
				console.error(`[nui] cannot find frame : ${msg.target}`);
			}
		} else {
			switch (msg.action) {
				case 'create_frame': {
					createFrame(msg.name, msg.url, msg.visible);
					break;
				}

				case 'focus_frame': {
					focusFrame(msg.name);
					break;
				}

				case 'blur_frame': {
					blurFrame(msg.name);
					break;
				}

				case 'show_frame': {
					showFrame(msg.name);
					break;
				}

				case 'hide_frame': {
					hideFrame(msg.name);
					break;
				}

				case 'top_frame': {
					topFrame(msg.name);
					break;
				}

				case 'destroy_frame': {
					destroyFrame(msg.name);
					break;
				}

				case 'play_sound' : {
					const audio = new Audio(msg.sound);

					if (msg.volume)
						audio.volume = msg.volume;

					audio.play();
					break;
				}

				case 'open_url' : {
					window.invokeNative('openUrl', msg.url);
					break;
				}

				case 'set_local_storage': {
					window.localStorage.setItem(msg.key, msg.value);
					break;
				}

				case 'get_local_storage': {
					$.post(`https://${RESOURCE_NAME}/nui:get_local_storage:response`, JSON.stringify({
						requestId: msg.requestId,
						value: window.localStorage.getItem(msg.key)
					}));

					break;
				}

				default:
					break;
			}
		}
	};

	window.addEventListener('message', e => { onMessage(e.data) });

	$.post(`https://${RESOURCE_NAME}/nui:ready`, '{}');
})();