ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Constants = {
    ResourceName = GetCurrentResourceName(),
    DisplayName = 'ZeeKota Multi Job',
    EventPrefix = 'zeekota_multijob',
    SupportedFrameworks = {
        esx = true,
        qb = true,
        ox = true
    },
    DutyModes = {
        State = 'state',
        OffJob = 'offjob'
    },
    HistoryActions = {
        AddJob = 'add_job',
        RemoveJob = 'remove_job',
        ChangeGrade = 'change_grade',
        ActiveJob = 'active_job',
        Duty = 'duty',
        Limit = 'limit',
        Import = 'import',
        Sync = 'sync'
    },
    ErrorCodes = {
        NotReady = 'NOT_READY',
        NoFramework = 'NO_FRAMEWORK',
        Database = 'DATABASE_ERROR',
        InvalidJob = 'INVALID_JOB',
        InvalidGrade = 'INVALID_GRADE',
        NotOwned = 'JOB_NOT_OWNED',
        MaxJobs = 'MAX_JOBS_REACHED',
        RateLimited = 'RATE_LIMITED',
        Permission = 'ACCESS_DENIED',
        Stale = 'STALE_CHARACTER_DATA',
        Busy = 'OPERATION_BUSY'
    }
}
