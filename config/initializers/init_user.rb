User = if ApplicationHelper::ENABLE_NO_LIMIT_HOTKEYS
    UserNoLimit
else
    UserBase
end
