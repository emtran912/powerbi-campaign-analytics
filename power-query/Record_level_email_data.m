let
    Source = Sql.Database(
        "reports-sql.london.edu",
        "EADReport",
        [
            Query="
                use eadreport

                select distinct
                    per.lbsno,
                    per.knownname,
                    per.surname,
                    per.sex,
                    per.aamember,
                    prg.progcode,
                    prg.progyear,
                    click.clickedURL,
                    click.clickedURLName,
                    click.CampaignName,
                    click.EventDate as [Click_Date]

                from person as per

                inner join program as prg on prg.lbsno = per.lbsno
                left join eipuserpreferences as eip on eip.lbsno = per.lbsno
                left join actitoclickstatistics as click on click.Email = eip.preferredemailaddress

                where click.email is not null
                and (
                    prg.status = '7 Graduated'
                    or prg.status = '7 Attended'
                    or prg.status = 'Student'
                    or per.aamember = 'Y'
                    or per.execedalumni = 'Y'
                )
                and click.campaignname like 'adv%'
                and click.EventDate BETWEEN '2024-08-01' AND '2027-12-31'
                order by Click_Date desc
            "
        ]
    ),

    // Reusable helper function for case-insensitive text matching
    ContainsAny = (text as nullable text, keywords as list) =>
        text <> null and List.AnyTrue(List.Transform(keywords, each Text.Contains(text, _, Comparer.OrdinalIgnoreCase))),

    // Configuration lists for different categories
    ExcludeKeywords = {"ballot", "staff", "internal", "copy", "test"},
    AppealKeywords = {"PC Post-Email", "Appeal", "Mop-Up", "60th Give", "Pledge", "Stewardship", "Phone Campaign", "donors", "GG", "gift"},
    EventKeywords = {"R4NA", "Festival of Minds", "Events Newsletter", "invitation", "invite", "event", "WAC", "reunion"},
    RankingKeywords = {"rankings", "FT", "Financial Times", "Bloomberg"},
    NewAlumniKeywords = {"R4NA", "FT rankings", "Welcome Alumni", "New Alumni", "congregation"},

    // Add date and time columns
    AddDateColumn = Table.AddColumn(Source, "Click_Date_Date", each Date.From([Click_Date]), type date),
    AddTimeColumn = Table.AddColumn(AddDateColumn, "Click_Date_Time", each Time.From([Click_Date]), type time),

    // Filter rows using helper function
    #"Filtered Rows" = Table.SelectRows(
        AddTimeColumn,
        each [CampaignName] <> null and not ContainsAny([CampaignName], ExcludeKeywords)
    ),

    // Add Campaign Category column
    #"Add Campaign Category" = Table.AddColumn(
        #"Filtered Rows",
        "Campaign Category",
        each 
            if ContainsAny([CampaignName], AppealKeywords) then "Appeal"
            else if Text.Contains([CampaignName], "Welcome Alumni Community", Comparer.OrdinalIgnoreCase) then "Welcome emails"
            else if ContainsAny([CampaignName], EventKeywords) then "Events"
            else if ContainsAny([CampaignName], RankingKeywords) then "Rankings"
            else if Text.Contains([CampaignName], "Newsletter", Comparer.OrdinalIgnoreCase) 
                 and not Text.Contains([CampaignName], "Events Newsletter", Comparer.OrdinalIgnoreCase) then "Alumni Newsletters"
            else "Other"
    ),

    // Add New Alumni? column
    #"New Alumni?" = Table.AddColumn(
        #"Add Campaign Category", 
        "New Alumni?", 
        each if ContainsAny([CampaignName], NewAlumniKeywords) then "Yes" else "No"
    ),

    // Clean URL - Remove everything after (and including) the hyphen and trim
    CleanedURL = Table.AddColumn(
        #"New Alumni?", 
        "Cleaned_Link_URL", 
        each 
            let
                link = [clickedURLName],
                url = [clickedURL],
                urlLower = Text.Lower(url),
                linkLower = Text.Lower(link),
                
                // URL mapping rules
                cleaned =
                    if link = "Find your WAC 2025" or link = "All WAC events" then "Find your local WAC"
                    else if Text.Contains(linkLower, "forever-forward") then "Forever Forward"
                    else if Text.Contains(urlLower, "forever-forward-gift") then "Make your gift"
                    else if Text.Contains(linkLower, "Update your email address") then "Update your contact details"
                    else if Text.Contains(urlLower, "globalgive") then "Global Give"
                    else if Text.Contains(urlLower, "spirit-of-98") then "Spirit of 98"
                    else 
                        let
                            lastHyphenPos = Text.PositionOf(link, "-", Occurrence.Last)
                        in
                            if lastHyphenPos >= 0 then Text.Trim(Text.Start(link, lastHyphenPos)) else link
            in
                cleaned
    ),

    // Add Cleaned Campaign Name column
    #"Cleaned Campaign Name" = Table.AddColumn(
        CleanedURL,
        "Cleaned Campaign Name",
        each 
            if [CampaignName] = "ADV-29-05-2025" then "ADV - PC Post-Email No Convo - 02.06.2025"
            else if Text.StartsWith([CampaignName], "ADV-", Comparer.OrdinalIgnoreCase) then Text.Trim(Text.Range([CampaignName], 4))
            else [CampaignName]
    ),

    // Update data types for all columns
    #"Updated Types" = Table.TransformColumnTypes(
        #"Cleaned Campaign Name",
        {
            {"lbsno", type text},
            {"knownname", type text},
            {"surname", type text},
            {"sex", type text},
            {"aamember", type text},
            {"progcode", type text},
            {"progyear", type text},
            {"clickedURL", type text},
            {"clickedURLName", type text},
            {"CampaignName", type text},
            {"Click_Date", type datetime},
            {"Click_Date_Date", type date},
            {"Click_Date_Time", type time},
            {"Campaign Category", type text},
            {"New Alumni?", type text},
            {"Cleaned_Link_URL", type text},
            {"Cleaned Campaign Name", type text}
        }
    ),
    #"Add Campaign Key" = Table.AddColumn(
        #"Updated Types", 
        "Campaign Key", 
        each Text.Remove(Text.Upper([CampaignName]), {" ", "-", "."})
    ),
    #"Merge with Campaign" = Table.NestedJoin(
        #"Add Campaign Key",
        {"Campaign Key"},
        dim_Campaign,
        {"Campaign Key"},
        "CampaignMatch",
        JoinKind.LeftOuter
    ),
    #"Expand Campaign ID" = Table.ExpandTableColumn(
        #"Merge with Campaign",
        "CampaignMatch",
        {"Campaign ID"},
        {"Campaign ID"}
    ),
    #"Remove Old Columns" = Table.RemoveColumns(
        #"Expand Campaign ID",
        {"Campaign Key", "CampaignName", "Campaign Category"}
    )
in
    #"Remove Old Columns"