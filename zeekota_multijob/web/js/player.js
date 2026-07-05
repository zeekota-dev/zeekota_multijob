(() => {
    const iconPaths = {
        briefcase: 'M4 7h16v11a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7Zm5-3h6l1 3H8l1-3Zm2 8h2',
        shield: 'M12 3 5 6v5c0 4 2.6 7 7 10 4.4-3 7-6 7-10V6l-7-3Z',
        medical: 'M10 4h4v6h6v4h-6v6h-4v-6H4v-4h6V4Z',
        wrench: 'M21 6.5a6 6 0 0 1-8 7.7L7 20l-3-3 5.8-6A6 6 0 0 1 17.5 3L14 6.5 17.5 10 21 6.5Z'
    };

    function icon(name) {
        const path = iconPaths[name] || iconPaths.briefcase;
        return `<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="${path}"/></svg>`;
    }

    function t(key, replacements) {
        return window.ZKApp.t(key, replacements);
    }

    function badge(job) {
        const dutyClass = job.onDuty ? 'on' : 'off';
        const dutyText = job.onDuty ? t('player_on_duty') : t('player_off_duty');
        const active = job.active ? `<span class="zk-badge active">${t('common_active')}</span>` : '';
        return `<div class="zk-badges">${active}<span class="zk-badge ${dutyClass}">${dutyText}</span></div>`;
    }

    function jobMeta(job, ui) {
        const parts = [job.gradeLabel || `${t('common_grade')} ${job.grade}`];
        if (ui.showGradeNumber) parts.push(`${t('common_grade')} ${job.grade}`);
        if (ui.showInternalJobName) parts.push(job.name);
        if (ui.showSalary && Number(job.salary) > 0) parts.push(`$${Number(job.salary).toLocaleString()}`);
        return parts.join(' - ');
    }

    function activeCard(payload) {
        const ui = payload.ui || {};
        const job = payload.activeJob;

        if (!job) {
            return `<section class="zk-panel zk-active-card"><h2>${t('player_active_job')}</h2><div class="zk-empty">${t('player_no_active_job')}</div></section>`;
        }

        const description = ui.showJobDescription && job.description ? `<p>${job.description}</p>` : '';
        const dutyLabel = job.onDuty ? t('player_go_off_duty') : t('player_go_on_duty');

        return `
            <section class="zk-panel zk-active-card">
                <h2>${t('player_active_job')}</h2>
                <div class="zk-job-heading" style="--job-color:${job.color}">
                    <div class="zk-job-icon">${icon(job.icon)}</div>
                    <div>
                        <h3>${job.label}</h3>
                        <p>${jobMeta(job, ui)}</p>
                    </div>
                </div>
                ${description}
                ${badge(job)}
                <button class="zk-button primary" type="button" data-player-action="duty" data-duty="${job.onDuty ? '0' : '1'}">${dutyLabel}</button>
            </section>
        `;
    }

    function jobRow(job, ui) {
        const disabled = !job.available || !job.canSwitch || job.active;
        const unavailableClass = job.available ? '' : ' unavailable';
        const action = job.active ? t('common_active') : t('player_switch_job');

        return `
            <article class="zk-job-row${unavailableClass}" style="--job-color:${job.color}">
                <div class="zk-job-icon">${icon(job.icon)}</div>
                <div class="zk-job-main">
                    <strong>${job.label}</strong>
                    <div class="zk-job-meta">${jobMeta(job, ui)}</div>
                    ${badge(job)}
                </div>
                <div class="zk-actions">
                    <button class="zk-button" type="button" data-player-action="switch" data-job="${job.name}" ${disabled ? 'disabled' : ''}>${action}</button>
                </div>
            </article>
        `;
    }

    function render(payload) {
        const jobs = payload.jobs || [];
        const ui = payload.ui || {};
        const limit = Number(payload.jobLimit);
        const slotsText = limit === -1
            ? t('player_unlimited_slots', { count: payload.allJobCount || jobs.length })
            : t('player_slots', { count: payload.allJobCount || jobs.length, limit });

        const list = jobs.length
            ? jobs.map((job) => jobRow(job, ui)).join('')
            : `<div class="zk-empty">${t('player_no_jobs_available')}</div>`;

        return `
            <div class="zk-player-grid">
                ${activeCard(payload)}
                <section class="zk-panel">
                    <div class="zk-toolbar">
                        <h2 class="zk-section-title">${t('player_stored_jobs')}</h2>
                        <span class="zk-badge">${slotsText}</span>
                        <button class="zk-button ghost" type="button" data-player-action="refresh">${t('admin_refresh')}</button>
                    </div>
                    <div class="zk-jobs-list">${list}</div>
                </section>
            </div>
        `;
    }

    async function handleClick(event) {
        const button = event.target.closest('[data-player-action]');
        if (!button || button.disabled) return;

        const action = button.dataset.playerAction;
        if (action === 'refresh') {
            await window.ZKApp.send('refreshPlayerData', {});
        }

        if (action === 'duty') {
            await window.ZKApp.withButton(button, () => window.ZKApp.send('setDuty', { onDuty: button.dataset.duty === '1' }));
        }

        if (action === 'switch') {
            const jobName = button.dataset.job;
            const confirmed = await window.ZKApp.confirm(t('player_confirm_job_switch'), t('player_switch_job'));
            if (confirmed) {
                await window.ZKApp.withButton(button, () => window.ZKApp.send('switchJob', { jobName }));
            }
        }
    }

    window.ZKPlayer = {
        render,
        handleClick
    };
})();
