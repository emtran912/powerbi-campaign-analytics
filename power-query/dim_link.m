let
    // ------------------------------------------------------------------
    // 1. Source: generic staging table
    // ------------------------------------------------------------------
    Source =
        stg_email_clicks,

    // ------------------------------------------------------------------
    // 2. Retain only link-level fields (dimension grain)
    // ------------------------------------------------------------------
    SelectColumns =
        Table.SelectColumns(
            Source,
            {
                "LinkUrl",
                "LinkLabel",
                "NormalisedUrl",
                "CampaignName",
                "CampaignKey"
            }
        ),

    // ------------------------------------------------------------------
    // 3. De-duplicate links
    // ------------------------------------------------------------------
    DistinctLinks =
        Table.Distinct(
            SelectColumns,
            {"LinkUrl", "CampaignKey"}
        ),

    // ------------------------------------------------------------------
    // 4. Helper function: case-insensitive keyword matching
    // ------------------------------------------------------------------
    ContainsAny =
        (text as nullable text, keywords as list) =>
            text <> null
                and List.AnyTrue(
                    List.Transform(
                        keywords,
                        each Text.Contains(text, _, Comparer.OrdinalIgnoreCase)
                    )
                ),

    // ------------------------------------------------------------------
    // 5. Keyword configuration (fully anonymised)
    // ------------------------------------------------------------------

    AdminKeywords =
        {
            "update details",
            "unsubscribe",
            "preferences",
            "social media"
        },

    EventsKeywords =
        {
            "event",
            "conference",
            "reunion",
            "registration",
            "webinar"
        },

    FundraisingKeywords =
        {
            "campaign",
            "appeal",
            "donate",
            "giving",
            "microsite"
        },

    TalentKeywords =
        {
            "scholarship",
            "financial support",
            "mentorship",
            "career"
        },

    InnovationKeywords =
        {
            "technology",
            "innovation",
            "entrepreneurship",
            "leadership"
        },

    SustainabilityKeywords =
        {
            "sustainability",
            "climate",
            "impact",
            "responsible business"
        },

    // ------------------------------------------------------------------
    // 6. Add theme column (priority-based classification)
    // ------------------------------------------------------------------
    AddTheme =
        Table.AddColumn(
            DistinctLinks,
            "LinkTheme",
            each
                let
                    textToMatch =
                        Text.Combine(
                            {
                                [LinkLabel],
                                [NormalisedUrl]
                            },
                            " "
                        )
                in
                    if ContainsAny(textToMatch, FundraisingKeywords) then
                        "Fundraising"
                    else if ContainsAny(textToMatch, AdminKeywords) then
                        "Admin"
                    else if ContainsAny(textToMatch, EventsKeywords) then
                        "Events"
                    else if ContainsAny(textToMatch, SustainabilityKeywords) then
                        "Sustainability"
                    else if ContainsAny(textToMatch, InnovationKeywords) then
                        "Innovation"
                    else if ContainsAny(textToMatch, TalentKeywords) then
                        "Talent"
                    else
                        "Other",
            type text
        )

in
    AddTheme