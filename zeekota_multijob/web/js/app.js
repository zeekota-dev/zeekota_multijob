(() => {
    const app = document.getElementById('zk-app');
    const content = document.getElementById('zk-content');
    const title = document.getElementById('zk-title');
    const character = document.getElementById('zk-character');
    const server = document.getElementById('zk-server');
    const subtitle = document.getElementById('zk-subtitle');
    const footer = document.getElementById('zk-footer-text');
    const version = document.getElementById('zk-version');
    const logo = document.getElementById('zk-logo');
    const closeButton = document.getElementById('zk-close');
    const modal = document.getElementById('zk-modal');
    const toasts = document.getElementById('zk-toasts');

    const state = {
        mode: null,
        payload: null,
        locale: {},
        ui: {}
    };

    document.documentElement.style.backgroundColor = 'transparent';
    document.body.style.backgroundColor = 'transparent';
    document.body.style.backgroundImage = 'none';

    function hardHide() {
        app.dataset.open = 'false';
        app.dataset.mode = 'closed';
        app.classList.add('zk-hidden');
        app.style.display = 'none';
        modal.classList.add('zk-hidden');
        modal.innerHTML = '';
    }

    function t(key, replacements) {
        let phrase = state.locale[key] || key;
        if (replacements) {
            Object.entries(replacements).forEach(([name, value]) => {
                phrase = phrase.split(`{${name}}`).join(String(value));
            });
        }
        return phrase;
    }

    function applyTheme(ui) {
        state.ui = ui || {};
        const colors = state.ui.colors || {};
        const effects = state.ui.effects || {};
        const root = document.documentElement;
        const map = {
            Accent: '--zk-accent',
            AccentSecondary: '--zk-accent-secondary',
            Background: '--zk-background',
            BackgroundOverlay: '--zk-background-overlay',
            Surface: '--zk-surface',
            SurfaceSecondary: '--zk-surface-secondary',
            SurfaceHover: '--zk-surface-hover',
            SurfaceActive: '--zk-surface-active',
            Border: '--zk-border',
            BorderHover: '--zk-border-hover',
            BorderActive: '--zk-border-active',
            TextPrimary: '--zk-text-primary',
            TextSecondary: '--zk-text-secondary',
            TextMuted: '--zk-text-muted',
            Success: '--zk-success',
            Warning: '--zk-warning',
            Danger: '--zk-danger',
            Info: '--zk-info',
            OnDuty: '--zk-on-duty',
            OffDuty: '--zk-off-duty',
            ActiveJob: '--zk-active-job'
        };

        Object.entries(map).forEach(([key, variable]) => {
            if (colors[key]) root.style.setProperty(variable, colors[key]);
        });

        root.style.setProperty('--zk-radius', `${Number(effects.BorderRadius || 12)}px`);
        root.style.setProperty('--zk-speed', `${Number(effects.AnimationSpeed || 180)}ms`);
        root.style.setProperty('--zk-blur', `${Number(effects.Blur || 14)}px`);
        root.style.setProperty('--zk-shadow-opacity', String(Number(effects.ShadowOpacity || 0.35)));
        app.classList.toggle('zk-blur', false);
    }

    function applyChrome(payload, admin) {
        const ui = payload.ui || {};
        const person = payload.character || {};
        applyTheme(ui);
        state.locale = payload.locale || {};
        title.textContent = admin ? ui.adminMenuTitle || t('admin_panel') : ui.menuTitle || t('player_multi_job');
        character.textContent = admin ? t('admin_panel') : person.name || '';
        server.textContent = ui.showServerName === false ? '' : ui.serverName || '';
        subtitle.textContent = ui.showServerSubtitle === false ? '' : ui.serverSubtitle || '';
        footer.textContent = ui.footerText || '';
        version.textContent = ui.showZeeKotaBranding === false ? `v${ui.version || ''}` : `ZeeKota - v${ui.version || ''}`;
        logo.style.width = `${ui.logoWidth || 72}px`;
        logo.style.height = `${ui.logoHeight || 72}px`;
        logo.src = ui.logo || ui.logoFallback || '';
        logo.onerror = () => {
            if (ui.logoFallback && logo.src.indexOf(ui.logoFallback) === -1) logo.src = ui.logoFallback;
        };
    }

    function open(mode, payload) {
        state.mode = mode;
        state.payload = payload;
        applyChrome(payload, mode === 'admin');
        content.innerHTML = mode === 'admin' ? window.ZKAdmin.render() : window.ZKPlayer.render(payload);
        app.style.display = 'grid';
        app.classList.remove('zk-hidden');
        app.dataset.mode = mode;
        app.dataset.open = 'true';
    }

    function close() {
        state.mode = null;
        state.payload = null;
        content.innerHTML = '';
        hardHide();
    }

    async function send(name, payload) {
        const response = await window.ZKApi.request(name, payload || {});
        if (!response.success) {
            toast(response.message || t('admin_action_failed'), 'error');
        } else if (response.message && response.message !== 'ok') {
            toast(response.message, 'success');
        }

        if (response.success && response.data && (name === 'switchJob' || name === 'setDuty' || name === 'refreshPlayerData')) {
            state.payload = response.data;
            applyChrome(response.data, false);
            content.innerHTML = window.ZKPlayer.render(response.data);
        }

        return response;
    }

    function renderAdmin() {
        content.innerHTML = window.ZKAdmin.render();
    }

    function toast(message, type) {
        const node = document.createElement('div');
        node.className = `zk-toast ${type || 'info'}`;
        node.textContent = message;
        toasts.appendChild(node);
        setTimeout(() => node.remove(), 4200);
    }

    function confirmDialog(heading, message) {
        return new Promise((resolve) => {
            modal.innerHTML = `
                <div class="zk-modal-card">
                    <h2>${heading}</h2>
                    <p>${message}</p>
                    <div class="zk-actions">
                        <button class="zk-button primary" type="button" data-modal="confirm">${t('player_confirm')}</button>
                        <button class="zk-button" type="button" data-modal="cancel">${t('player_cancel')}</button>
                    </div>
                </div>
            `;
            modal.classList.remove('zk-hidden');
            modal.onclick = (event) => {
                const button = event.target.closest('[data-modal]');
                if (!button) return;
                modal.classList.add('zk-hidden');
                modal.innerHTML = '';
                resolve(button.dataset.modal === 'confirm');
            };
        });
    }

    async function withButton(button, task) {
        button.disabled = true;
        try {
            return await task();
        } finally {
            button.disabled = false;
        }
    }

    closeButton.addEventListener('click', () => {
        window.ZKApi.close();
        close();
    });

    document.addEventListener('keyup', (event) => {
        if (event.key === 'Escape' && !app.classList.contains('zk-hidden')) {
            window.ZKApi.close();
            close();
        }
    });

    content.addEventListener('click', (event) => {
        if (state.mode === 'player') window.ZKPlayer.handleClick(event);
        if (state.mode === 'admin') window.ZKAdmin.handleClick(event);
    });

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        const payload = data.payload || {};

        if (data.action === 'openPlayer') {
            open('player', payload);
        }

        if (data.action === 'openAdmin') {
            window.ZKAdmin.open(payload);
            open('admin', payload);
        }

        if (data.action === 'close') {
            close();
        }

        if (data.action === 'toast') {
            toast(payload.message || '', payload.type || 'info');
        }

        if (data.action === 'playerData') {
            state.payload = payload;
            if (state.mode === 'player') {
                applyChrome(payload, false);
                content.innerHTML = window.ZKPlayer.render(payload);
            }
        }
    });

    window.ZKApp = {
        t,
        send,
        toast,
        confirm: confirmDialog,
        withButton,
        renderAdmin
    };

    hardHide();
})();
