local Translations = {
    text = {
        enter_house = '~g~E~w~ - Vstoupit do domu',
        enter_requirements = 'Lomítko | Sada šroubováků',
        leave_house = '~g~E~w~ - Opustit dům',
        search = '~g~E~w~ - Prohledat okolí',
        pickup = '~g~E~w~ - Sebrat %{Item}'
    },
    notify = {
        no_police = 'Nedostatek Policistů (%{Required} Požadováno)',
        fail_skillcheck = 'Selhalo Skillcheck',
        success_skillcheck = 'Úspěšný Skillcheck',
        busy = 'Někdo už na tom pracuje',
        police_alert = 'Podezřelá aktivita poblíž vlastněné nemovitosti'
    }
}

if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
--translate by stepan_valic