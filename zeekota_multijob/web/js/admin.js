(() => {
    const state = {
        tab: 'dashboard',
        sessionId: '',
        dashboard: {},
        online: { players: [] },
        offline: { characters: [] },
        selected: null,
        history: { history: [] },
        jobs: []
    };

    function t(key, replacements) {
        return window.ZKApp.t(key, replacements);
    }

    function session(payload) {
        return Object.assign({ sessionId: state.sessionId }, payload || {});
    }

    function stat(label, value) {
        return `<div class="zk-stat"><span>${label}</span><strong>${value}</strong></div>`;
    }

    function tabs() {
        const items = [
            ['dashboard', t('admin_dashboard')],
            ['online', t('admin_online_players')],
            ['offline', t('admin_offline_characters')],
            ['detail', t('admin_select_character')]
        ];

        return `<nav class="zk-tabs">${items.map(([id, label]) => `<button class="zk-tab ${state.tab === id ? 'active' : ''}" type="button" data-admin-tab="${id}">${label}</button>`).join('')}</nav>`;
    }

    function dashboard() {
        const data = state.dashboard || {};
        return `
            <section class="zk-panel">
                <h2>${t('admin_dashboard')}</h2>
                <div class="zk-stats">
                    ${stat(t('common_online'), data.onlinePlayers || 0)}
                    ${stat(t('common_count'), data.totalJobs || 0)}
                    ${stat(t('common_active'), data.activeJobs || 0)}
                    ${stat(t('player_on_duty'), data.onDutyJobs || 0)}
                </div>
            </section>
        `;
    }

    function listItem(character, online) {
        const source = online ? `<span class="zk-badge">${t('common_source')} ${character.source}</span>` : '';
        const meta = `${character.identifier} - ${character.job || t('common_none')} (${character.grade || 0})`;
        return `
            <article class="zk-list-item">
                <div>
                    <strong class="zk-list-title">${character.name}</strong>
                    <div class="zk-list-meta">${meta}</div>
                </div>
                <div class="zk-actions">
                    ${source}
                    <button class="zk-button" type="button" data-admin-action="select" data-framework="${character.framework}" data-identifier="${character.identifier}">${t('player_details')}</button>
                </div>
            </article>
        `;
    }

    function searchPanel(kind) {
        const isOnline = kind === 'online';
        const data = isOnline ? state.online : state.offline;
        const items = isOnline ? data.players || [] : data.characters || [];
        const action = isOnline ? 'searchOnline' : 'searchOffline';
        const title = isOnline ? t('admin_online_players') : t('admin_offline_characters');

        return `
            <section class="zk-panel">
                <h2>${title}</h2>
                <div class="zk-toolbar">
                    <input class="zk-input" data-admin-search="${kind}" maxlength="64" placeholder="${isOnline ? t('admin_search_players') : t('admin_search_characters')}">
                    <button class="zk-button" type="button" data-admin-action="${action}">${t('admin_search')}</button>
                </div>
                <div class="zk-list">
                    ${items.length ? items.map((item) => listItem(item, isOnline)).join('') : `<div class="zk-empty">${t('admin_character_not_found')}</div>`}
                </div>
            </section>
        `;
    }

    function jobOptions() {
        return (state.jobs || []).map((job) => `<option value="${job.name}">${job.label}</option>`).join('');
    }

    function detailPanel() {
        const selected = state.selected;
        if (!selected) {
            return `<section class="zk-panel"><div class="zk-empty">${t('admin_select_character')}</div></section>`;
        }

        const jobs = selected.jobs || [];
        const rows = jobs.map((job) => `
            <article class="zk-list-item">
                <div>
                    <strong class="zk-list-title">${job.label}</strong>
                    <div class="zk-list-meta">${job.name} - ${t('common_grade')} ${job.grade} - ${job.onDuty ? t('player_on_duty') : t('player_off_duty')}</div>
                </div>
                <div class="zk-actions">
                    ${job.active ? `<span class="zk-badge active">${t('common_active')}</span>` : `<button class="zk-button" type="button" data-admin-action="setActive" data-job="${job.name}">${t('admin_change_active_job')}</button>`}
                    <button class="zk-button" type="button" data-admin-action="toggleDuty" data-job="${job.name}" data-duty="${job.onDuty ? '0' : '1'}">${job.onDuty ? t('player_go_off_duty') : t('player_go_on_duty')}</button>
                    <button class="zk-button danger" type="button" data-admin-action="removeJob" data-job="${job.name}">${t('admin_remove_job')}</button>
                </div>
            </article>
        `).join('');

        const history = (state.history.history || []).map((item) => `
            <article class="zk-list-item">
                <div>
                    <strong class="zk-list-title">${item.action}</strong>
                    <div class="zk-list-meta">${item.job_name || item.old_job_name || t('common_none')} - ${item.actor_name || t('common_unknown')} - ${item.created_at || ''}</div>
                </div>
                <span class="zk-badge">${item.reason || t('common_none')}</span>
            </article>
        `).join('');

        return `
            <section class="zk-admin-detail">
                <div class="zk-toolbar">
                    <h2>${selected.name}</h2>
                    <span class="zk-badge">${selected.online ? t('common_online') : t('common_offline')}</span>
                    <span class="zk-badge">${t('common_limit')}: ${selected.jobLimit}</span>
                </div>
                <div class="zk-list">${rows || `<div class="zk-empty">${t('player_no_jobs_available')}</div>`}</div>
            </section>
            <section class="zk-panel">
                <h2>${t('admin_add_job')}</h2>
                <div class="zk-form-grid">
                    <div class="zk-field"><label>${t('common_job')}</label><select class="zk-select" data-admin-input="jobName">${jobOptions()}</select></div>
                    <div class="zk-field"><label>${t('common_grade')}</label><input class="zk-input" type="number" min="0" value="0" data-admin-input="grade"></div>
                    <div class="zk-field"><label>${t('common_limit')}</label><input class="zk-input" type="number" min="-1" value="${selected.jobLimit}" data-admin-input="limit"></div>
                    <div class="zk-field"><label>${t('common_status')}</label><div class="zk-checks"><label><input type="checkbox" data-admin-input="active"> ${t('common_active')}</label><label><input type="checkbox" data-admin-input="onDuty"> ${t('player_on_duty')}</label></div></div>
                    <div class="zk-field" style="grid-column:1/-1"><label>${t('admin_action_reason')}</label><textarea class="zk-textarea" maxlength="180" data-admin-input="reason"></textarea></div>
                </div>
                <div class="zk-actions">
                    <button class="zk-button primary" type="button" data-admin-action="addJob">${t('admin_add_job')}</button>
                    <button class="zk-button" type="button" data-admin-action="changeGrade">${t('admin_change_grade')}</button>
                    <button class="zk-button" type="button" data-admin-action="setLimit">${t('admin_set_job_limit')}</button>
                </div>
            </section>
            <section class="zk-panel">
                <h2>${t('admin_job_history')}</h2>
                <div class="zk-list">${history || `<div class="zk-empty">${t('admin_no_history_found')}</div>`}</div>
            </section>
        `;
    }

    function render() {
        const body = state.tab === 'dashboard'
            ? dashboard()
            : state.tab === 'online'
                ? searchPanel('online')
                : state.tab === 'offline'
                    ? searchPanel('offline')
                    : detailPanel();

        return `<div class="zk-admin-layout">${tabs()}<div class="zk-admin-body">${body}</div></div>`;
    }

    async function refreshCharacter(framework, identifier) {
        const details = await window.ZKApp.send('adminCharacterDetails', session({ framework, identifier }));
        if (details.success) {
            state.selected = details.data;
            const history = await window.ZKApp.send('adminHistory', session({ framework, identifier }));
            if (history.success) state.history = history.data;
            state.tab = 'detail';
            window.ZKApp.renderAdmin();
        }
    }

    function values() {
        const root = document.getElementById('zk-content');
        const get = (name) => root.querySelector(`[data-admin-input="${name}"]`);
        return {
            jobName: get('jobName') && get('jobName').value,
            grade: Number(get('grade') && get('grade').value || 0),
            limit: Number(get('limit') && get('limit').value || 0),
            active: get('active') && get('active').checked,
            onDuty: get('onDuty') && get('onDuty').checked,
            reason: get('reason') && get('reason').value || ''
        };
    }

    async function mutate(action, extra) {
        if (!state.selected) return;
        const payload = Object.assign(session({
            framework: state.selected.framework,
            identifier: state.selected.identifier
        }), values(), extra || {});
        const response = await window.ZKApp.send(action, payload);
        if (response.success) {
            await refreshCharacter(state.selected.framework, state.selected.identifier);
        }
    }

    async function handleClick(event) {
        const tab = event.target.closest('[data-admin-tab]');
        if (tab) {
            state.tab = tab.dataset.adminTab;
            window.ZKApp.renderAdmin();
            return;
        }

        const button = event.target.closest('[data-admin-action]');
        if (!button || button.disabled) return;
        const action = button.dataset.adminAction;

        if (action === 'searchOnline') {
            const search = document.querySelector('[data-admin-search="online"]').value;
            const response = await window.ZKApp.send('adminOnlinePlayers', session({ search }));
            if (response.success) state.online = response.data;
            window.ZKApp.renderAdmin();
        }

        if (action === 'searchOffline') {
            const search = document.querySelector('[data-admin-search="offline"]').value;
            const response = await window.ZKApp.send('adminOfflineSearch', session({ search }));
            if (response.success) state.offline = response.data;
            window.ZKApp.renderAdmin();
        }

        if (action === 'select') {
            await refreshCharacter(button.dataset.framework, button.dataset.identifier);
        }

        if (action === 'addJob') await window.ZKApp.withButton(button, () => mutate('adminAddJob'));
        if (action === 'changeGrade') await window.ZKApp.withButton(button, () => mutate('adminChangeGrade'));
        if (action === 'setLimit') await window.ZKApp.withButton(button, () => mutate('adminSetLimit'));
        if (action === 'setActive') await window.ZKApp.withButton(button, () => mutate('adminSetActive', { jobName: button.dataset.job }));
        if (action === 'toggleDuty') await window.ZKApp.withButton(button, () => mutate('adminSetDuty', { jobName: button.dataset.job, onDuty: button.dataset.duty === '1' }));
        if (action === 'removeJob') {
            const confirmed = await window.ZKApp.confirm(t('admin_remove_job'), button.dataset.job);
            if (confirmed) await window.ZKApp.withButton(button, () => mutate('adminRemoveJob', { jobName: button.dataset.job }));
        }
    }

    function open(payload) {
        state.sessionId = payload.sessionId;
        state.dashboard = payload.dashboard || {};
        state.online = payload.online || { players: [] };
        state.jobs = payload.jobs || [];
        state.tab = 'dashboard';
    }

    window.ZKAdmin = {
        state,
        open,
        render,
        handleClick
    };
})();
