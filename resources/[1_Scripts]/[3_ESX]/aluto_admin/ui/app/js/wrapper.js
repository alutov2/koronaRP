(() => {
	const wrapper = {};

	wrapper.messageSize = 1024;
	wrapper.messageId = 0;
	wrapper.resourceName = GetParentResourceName();

	window.SendMessage = (namespace, type, msg) => {
		wrapper.messageId = (wrapper.messageId < 65535) ? wrapper.messageId + 1 : 0;
		const messageId = wrapper.messageId;

		const str = JSON.stringify(msg);

		for (let i = 0; i < str.length; i++) {
			let count = 0;
			let chunk = '';

			while (count < wrapper.messageSize && i < str.length) {
				chunk += str[i];

				count++;
				i++;
			}

			i--;

			const data = {
				__namespace: namespace,
				__type: type,
				id: messageId,
				chunk: chunk
			}

			if (i == str.length - 1)
				data.end = true;

			$.post(`https://${wrapper.resourceName}/__chunk`, JSON.stringify(data));
		}
	}
})();