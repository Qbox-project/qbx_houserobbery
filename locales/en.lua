local Translations = {
    text = {
        enter_house = '~g~E~w~ - Enter House',
        enter_requirements = 'Lockpick | Screwdriver set',
        leave_house = '~g~E~w~ - Leave House',
        search = '~g~E~w~ - Search Around',
        pickup = '~g~E~w~ - Grab %{Item}'
    },
    notify = {
        no_police = 'Not Enough Police (%{Required} Required)',
        fail_skillcheck = 'Failed Skillcheck',
        success_skillcheck = 'Successful Skillcheck',
        busy = 'Someone is already on it',
        police_alert = 'Suspicious activity near owned property'
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
