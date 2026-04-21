let

    // 1. Source: SQL query
    Source =
        Sql.Database(
            ServerName,      // Parameter
            DatabaseName,    // Parameter
            [
                Query = "
                    USE DatabaseName;

                    SELECT DISTINCT
                        per.recordid,
                        click.clickedURL,
                        click.clickedURLName,
                        click.CampaignName,
                        click.EventDate AS Click_Date,
                        click.CampaignID
                    FROM table_person AS per
                    INNER JOIN table_program AS prg
                        ON prg.recordid = per.recordid
                    LEFT JOIN table_preferences AS eip
                        ON eip.recordid = per.recordid
                    LEFT JOIN table_clickstats AS click
                        ON click.Email = eip.preferredemailaddress
                    WHERE
                        click.email IS NOT NULL
                        AND (
                            prg.status = 'Status1'
                            OR prg.status = 'Status2'
                            OR prg.status = 'Status3'
                            OR per.flag1 = 'Y'
                            OR per.flag2 = 'Y'
                        )
                        AND click.campaignname LIKE 'prefix%'
                        AND click.EventDate BETWEEN '2024-08-01' AND '2027-12-31'
                    ORDER BY Click_Date DESC
                "
            ]
        ),

    // 2. Helper function (case-insensitive keyword matching)
    ContainsAny =
        (text as nullable text, keywords as list) =>
            text <> null
                and List.AnyTrue(
                    List.Transform(
                        keywords,
                        each Text.Contains(text, _, Comparer.OrdinalIgnoreCase)
                    )
                ),

    // 3. Configuration lists

    ExcludeKeywords =
        {"keyword1", "keyword2", "keyword3", "keyword4", "keyword5"},

    NewAlumniKeywords =
        {"keyword1", "keyword2", "keyword3", "keyword4", "keyword5"},

    // 4. Filter rows
    FilteredRows =
        Table.SelectRows(
            Source,
            each
                [CampaignName] <> null
                and not ContainsAny([CampaignName], ExcludeKeywords)
        ),

    // 5. Add derived columns
    AddColumns =
        Table.AddColumn(
            Table.AddColumn(
                Table.AddColumn(
                    FilteredRows,
                    "Click_Date_Date",
                    each Date.From([Click_Date]),
                    type date
                ),
                "Click_Date_Time",
                each Time.From([Click_Date]),
                type time
            ),
            "Cleaned_Link_URL",
            each
                let
                    link = [clickedURLName],
                    url = [clickedURL],
                    linkLower = Text.Lower(link),
                    urlLower = Text.Lower(url)
                in
                    // URL cleaning logic based on pattern matching
                    if link = "Link Pattern 1" or link = "Link Pattern 2" then
                        "Cleaned Link 1"
                    else if Text.Contains(linkLower, "campaign-keyword-1") then
                        "Campaign 1"
                    else if Text.Contains(urlLower, "campaign-keyword-2") then
                        "Call to Action 1"
                    else if Text.Contains(urlLower, "update-keyword") then
                        "Update Contact Details"
                    else if Text.Contains(urlLower, "campaign-keyword-3") then
                        "Campaign 2"
                    else if Text.Contains(urlLower, "campaign-keyword-4") then
                        "Campaign 3"
                    else
                        // Generic text cleaning: remove suffix after last hyphen
                        let
                            lastHyphenPos =
                                Text.PositionOf(link, "-", Occurrence.Last)
                        in
                            if lastHyphenPos >= 0 then
                                Text.Trim(Text.Start(link, lastHyphenPos))
                            else
                                link
        )

in
    AddColumns