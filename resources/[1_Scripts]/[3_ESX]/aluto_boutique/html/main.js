window.addEventListener('message', (event) => {
    console.log
    if (event.data.type === 'openLink') {
        window.invokeNative('openUrl', event.data.url);
    };
});