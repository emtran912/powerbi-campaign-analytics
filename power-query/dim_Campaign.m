let
    Source = fact_campaign,

    // Case-insensitive keyword matcher
    ContainsAny = (text as nullable text, keywords as list) =>
        text <> null
        and List.AnyTrue(
            List.Transform(
                keywords,
                each Text.Contains(text, _, Comparer.OrdinalIgnoreCase)
            )
        ),

    // Campaign category keyword lists
    // Note: Actual keywords removed for institutional privacy
    AppealKeywords = {"keyword1", "keyword2", "keyword3", "..."},
    EventKeywords = {"keyword1", "keyword2", "keyword3", "..."},
    AdministrativeKeywords = {"keyword1", "keyword2", "..."},
    NewCustomerKeywords = {"keyword1", "keyword2", "..."},

    // Keep campaign attributes
    #"Selected Campaign Columns" =
        Table.SelectColumns(
            Source,
            {
                "campaignId",
                "Campaign name",
                "Sent date"
            }
        ),

    // Add Campaign Category (single source of truth)
    #"Added Campaign Category" =
        Table.AddColumn(
            Table.AddColumn(
                #"Selected Campaign Columns",
                "Campaign Category",
                each
                    if ContainsAny([Campaign name], PromoKeywords) then "Promotions"
                    else if ContainsAny([Campaign name], EventKeywords) then "Events"
                    else if ContainsAny([Campaign name], AdministrativeKeywords) then "Administrative"
                    else if
                        ContainsAny([Campaign name], {"Newsletter"})
                        and not ContainsAny([Campaign name], {"Events Newsletter"})
                    then "Newsletters"
                    else "Other",
                type text
            ),
            "New customer?",
            each 
                if ContainsAny([Campaign name], NewCustomerKeywords) then "Yes" else "No",
                type text
        ),

    // Remove duplicates (guarantee one row per campaign)
    #"Removed Duplicates" =
        Table.Distinct(#"Added Campaign Category"),

    // Rename for clarity
    #"Renamed Columns" =
        Table.RenameColumns(
            #"Removed Duplicates",
            {
                {"Campaign name", "Campaign Name"},
                {"campaignId", "Campaign ID"}
            }
        )
in
    #"Renamed Columns"