(() => {
    const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'zeekota_multijob';

    async function post(action, payload) {
        const response = await fetch(`https://${resource}/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload || {})
        });

        return response.json();
    }

    window.ZKApi = {
        close: () => post('close', {}),
        request: (name, payload) => post('request', { name, payload: payload || {} })
    };
})();
