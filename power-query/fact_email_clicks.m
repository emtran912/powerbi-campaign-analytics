let
    Source = stg_email_clicks,

    // Keep only fact-level attributes
    #"Selected Fact Columns" =
        Table.SelectColumns(
            Source,
            {
                "lbsno",
                "Click_Date",
                "Click_Date_Date",
                "Click_Date_Time",
                "clickedURL",
                "Cleaned_Link_URL",
                "CampaignID"
            }
        )
in
    #"Selected Fact Columns"