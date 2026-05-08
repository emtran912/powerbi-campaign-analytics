let
    // ------------------------------------------------------------
    // 1. Source: SQL database (no native query)
    // ------------------------------------------------------------
    Source =
        Sql.Database(
            ServerName,      // Parameter
            DatabaseName     // Parameter
        ),

    PersonTable = Source{[Schema="dbo", Item="table_person"]}[Data],
    ProgrammeTable = Source{[Schema="dbo", Item="table_program"]}[Data],
    PreferencesTable = Source{[Schema="dbo", Item="table_preferences"]}[Data],
    ClicksRaw = Source{[Schema="dbo", Item="table_clickstats"]}[Data],

    // ------------------------------------------------------------
    // 2. Incremental refresh filter (must be early)
    // ------------------------------------------------------------
    Clicks =
        Table.SelectRows(
            ClicksRaw,
            each [EventDate] >= RangeStart and [EventDate] < RangeEnd
        ),

    // ------------------------------------------------------------
    // 3. Filter click events (foldable)
    // ------------------------------------------------------------
    FilteredClicks =
        Table.SelectRows(
            Clicks,
            each
                [Email] <> null
                and Text.StartsWith([CampaignName], "prefix")
        ),

    // ------------------------------------------------------------
    // 4. Merge reference tables (foldable joins)
    // ------------------------------------------------------------
    MergePreferences =
        Table.NestedJoin(
            FilteredClicks,
            {"Email"},
            PreferencesTable,
            {"PreferredEmailAddress"},
            "Preferences",
            JoinKind.LeftOuter
        ),

    ExpandPreferences =
        Table.ExpandTableColumn(
            MergePreferences,
            "Preferences",
            {"RecordId"}
        ),

    MergePerson =
        Table.NestedJoin(
            ExpandPreferences,
            {"RecordId"},
            PersonTable,
            {"RecordId"},
            "Person",
            JoinKind.Inner
        ),

    ExpandPerson =
        Table.ExpandTableColumn(
            MergePerson,
            "Person",
            {"Flag1", "Flag2"}
        ),

    MergeProgramme =
        Table.NestedJoin(
            ExpandPerson,
            {"RecordId"},
            ProgrammeTable,
            {"RecordId"},
            "Programme",
            JoinKind.Inner
        ),

    ExpandProgramme =
        Table.ExpandTableColumn(
            MergeProgramme,
            "Programme",
            {"Status"}
        ),

    // ------------------------------------------------------------
    // 5. Business rule filters
    // ------------------------------------------------------------
    FilteredRows =
        Table.SelectRows(
            ExpandProgramme,
            each
                ([Status] = "Status1"
                or [Status] = "Status2"
                or [Status] = "Status3"
                or [Flag1] = "Y"
                or [Flag2] = "Y")
        ),

    // ------------------------------------------------------------
    // 6. Derived columns (non-folding beyond this point)
    // ------------------------------------------------------------
    AddClickDate =
        Table.AddColumn(
            FilteredRows,
            "Click_Date_Date",
            each Date.From([EventDate]),
            type date
        ),

    AddClickTime =
        Table.AddColumn(
            AddClickDate,
            "Click_Date_Time",
            each Time.From([EventDate]),
            type time
        ),

    AddCleanedLink =
        Table.AddColumn(
            AddClickTime,
            "Cleaned_Link_URL",
            each
                let
                    linkText = try Text.From([ClickedUrlName]) otherwise null,
                    linkUrl = try Text.From([ClickedUrl]) otherwise null,

                    linkLower =
                        if linkText <> null then Text.Lower(linkText) else null,
                    urlLower =
                        if linkUrl <> null then Text.Lower(linkUrl) else null,

                    lastHyphenPos =
                        if linkText <> null then
                            Text.PositionOf(linkText, "-", Occurrence.Last)
                        else
                            -1
                in
                    if linkLower <> null
                        and Text.Contains(linkLower, "pattern-one") then
                        "Generic Link Label 1"

                    else if urlLower <> null
                        and Text.Contains(urlLower, "call-to-action") then
                        "Generic Call to Action"

                    else if urlLower <> null
                        and Text.Contains(urlLower, "update-details") then
                        "Update contact details"

                    else if linkText <> null and lastHyphenPos >= 0 then
                        Text.Trim(Text.Start(linkText, lastHyphenPos))

                    else
                        linkText,
            type nullable text
        )

in
    AddCleanedLink