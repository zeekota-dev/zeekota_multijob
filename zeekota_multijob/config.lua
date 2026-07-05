Config = Config or {}

Config.Framework = 'auto'
Config.Locale = 'en'
Config.Debug = false
Config.Version = '1.0.0'

Config.FrameworkResources = {
    esx = 'es_extended',
    qb = 'qb-core',
    ox = 'ox_core'
}

Config.Database = {
    ValidateTables = true,
    RequiredTables = {
        'zeekota_multijob_jobs',
        'zeekota_multijob_limits',
        'zeekota_multijob_history'
    },
    FrameworkTables = {
        ESXUsers = 'users',
        QBPlayers = 'players',
        OxCharacters = 'characters'
    }
}

Config.PlayerMenu = {
    Command = 'jobs',
    EnableCommand = true,
    EnableKeybind = true,
    DefaultKey = 'F4',
    CloseWhenDead = true
}

Config.Admin = {
    Enabled = true,
    Command = 'multijobadmin',
    AcePermission = 'zeekota_multijob.admin',
    AllowAce = true,
    AllowFrameworkGroups = true,
    AllowIdentifiers = false,
    RequireReason = true,
    ReasonMaxLength = 180,
    PageSize = 12,
    HistoryPageSize = 10,
    Groups = {
        esx = { 'admin', 'superadmin', 'owner' },
        qb = { 'admin', 'god' },
        ox = { 'admin', 'owner' }
    },
    Identifiers = {
    },
    RateLimits = {
        Search = 500,
        ViewCharacter = 500,
        AddJob = 1500,
        RemoveJob = 1500,
        ChangeGrade = 1000,
        ChangeActiveJob = 1500,
        ChangeDuty = 750,
        ChangeJobLimit = 1500,
        ViewHistory = 750
    }
}

Config.JobLimits = {
    Default = 3,
    Minimum = 1,
    Maximum = 12,
    UnlimitedValue = -1
}

Config.RateLimits = {
    OpenMenu = 500,
    RefreshJobs = 750,
    SwitchJob = 1500,
    ChangeDuty = 750
}

Config.Sync = {
    ImportCurrentJob = true,
    CaptureExternalJobChanges = true,
    ReconcileOnLogin = true,
    ReconcileOnResourceStart = true,
    ImportDutyState = true,
    ResetDutyOnResourceRestart = false
}

Config.Switching = {
    AllowWhileOnDuty = true,
    AutoOffDutyWhenSwitching = false,
    RestoreDutyWhenSwitching = true,
    DefaultDutyState = false,
    PreserveDutyByJob = true,
    BlockWhileDead = true,
    BlockWhileCuffed = true,
    BlockDuringCombat = false,
    CombatTimeoutSeconds = 20
}

Config.ESX = {
    DutyMode = 'state',
    OffDutyJobs = {
        police = 'offpolice',
        ambulance = 'offambulance',
        mechanic = 'offmechanic'
    },
    ReconnectDutyState = 'restore',
    ResetDutyAfterRestart = false,
    ShowOffDutyJobs = false,
    PreserveGradeBetweenDutyJobs = true,
    AutoCreateFromJobChanges = true
}

Config.QBCore = {
    DefaultDutyWhenMissing = false,
    SavePlayerAfterJobChange = true
}

Config.Ox = {
    JobGroupType = 'job',
    DutyStatusName = 'duty',
    OfflineJobStorage = 'zeekota',
    CharacterIdColumn = 'charid'
}

Config.ExcludedJobs = {
    unemployed = {
        store = true,
        display = false,
        fallback = true,
        allowSwitch = false,
        allowAdminAssign = false,
        removeAutomatically = false
    }
}

Config.ProtectedJobs = {
    unemployed = true
}

Config.JobDisplay = {
    police = {
        label = 'Los Santos Police Department',
        description = 'Protect and serve the citizens of Los Santos.',
        icon = 'shield',
        color = '#3B82F6'
    },
    ambulance = {
        label = 'Emergency Medical Services',
        description = 'Provide medical care and emergency response.',
        icon = 'medical',
        color = '#EF4444'
    },
    mechanic = {
        label = 'Automotive Technician',
        description = 'Repair, upgrade, and maintain city vehicles.',
        icon = 'wrench',
        color = '#F59E0B'
    }
}

Config.UI = {
    ServerName = 'ZeeKota Roleplay',
    ServerSubtitle = 'Choose Your Career',
    MenuTitle = 'Multi Job',
    AdminMenuTitle = 'Multi Job Administration',
    Logo = 'assets/logo.png',
    LogoFallback = 'assets/logo.png',
    LogoWidth = 72,
    LogoHeight = 72,
    ShowServerName = true,
    ShowServerSubtitle = true,
    ShowZeeKotaBranding = true,
    ShowSalary = true,
    ShowInternalJobName = false,
    ShowGradeNumber = false,
    ShowJobDescription = true,
    FooterText = 'Manage your careers and duty status.',
    Colors = {
        Accent = '#E63946',
        AccentSecondary = '#8B0000',
        Background = '#06070A',
        BackgroundOverlay = 'rgba(0, 0, 0, 0.34)',
        Surface = '#10131A',
        SurfaceSecondary = '#171B25',
        SurfaceHover = '#222838',
        SurfaceActive = '#2A3142',
        Border = 'rgba(255, 255, 255, 0.12)',
        BorderHover = 'rgba(255, 255, 255, 0.24)',
        BorderActive = 'rgba(230, 57, 70, 0.65)',
        TextPrimary = '#FFFFFF',
        TextSecondary = '#A9AFBB',
        TextMuted = '#6F7682',
        Success = '#4ADE80',
        Warning = '#FBBF24',
        Danger = '#EF4444',
        Info = '#60A5FA',
        OnDuty = '#4ADE80',
        OffDuty = '#9CA3AF',
        ActiveJob = '#E63946'
    },
    Effects = {
        Blur = 14,
        BorderRadius = 12,
        ShadowOpacity = 0.35,
        GlowOpacity = 0.18,
        AnimationSpeed = 180,
        EnableBackdropBlur = false,
        EnableGlow = true,
        ReduceMotion = false
    }
}

Config.Notify = 'framework'

Config.CustomNotify = function(source, message, notificationType)
    TriggerClientEvent('zeekota_multijob:client:notify', source, {
        type = notificationType or 'info',
        message = message
    })
end

Config.Webhooks = {
    Enabled = false,
    Url = '',
    Username = 'ZeeKota Multi Job',
    AvatarUrl = '',
    MentionRole = ''
}

Config.Restrictions = {
    IsPlayerCuffed = function(source)
        local state = Player(source).state
        return state and (state.isCuffed == true or state.cuffed == true) or false
    end,
    IsPlayerInCombat = function(source)
        local state = Player(source).state
        return state and state.zeekotaInCombat == true or false
    end,
    CanAssignJob = function(adminSource, targetIdentifier, jobName, grade)
        return true
    end,
    CanRemoveJob = function(adminSource, targetIdentifier, jobName)
        return true
    end
}
