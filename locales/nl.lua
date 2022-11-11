local Translations = {
    text = {
        enter_house = '~g~E~w~ - Betreed huis',
        enter_requirements = 'Lockpick | Schroevendraaier set',
        leave_house = '~g~E~w~ - Verlaat huis',
        search = '~g~E~w~ - Zoeken',
        pickup = '~g~E~w~ - Pak %{Item}'
    },
    notify = {
        no_police = 'Niet genoeg politie (%{Required} Required)',
        fail_skillcheck = 'Skillcheck gefaald',
        success_skillcheck = 'Skillcheck gelukt',
        busy = 'Er is al iemand hiermee bezig',
        police_alert = 'Verdachte activiteit in de buurt van een woning'
    }
}

if GetConvar('qb_locale', 'en') == 'nl' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end