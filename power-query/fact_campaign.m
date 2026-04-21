let
    // 0. Load all files from campaign-level report folder
    Source = Folder.Files(CampaignReportPath), // Parameter or config value

    // 1. Exclude hidden/system files
    #"Filtered Hidden Files" =
        Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),

    // 2. Apply Transform File function to each file
    #"Invoke Transform File" =
        Table.AddColumn(
            #"Filtered Hidden Files",
            "Transform File",
            each #"Transform File (3)"([Content])
        ),

    // 3. Rename file name column
    #"Renamed Source Column" =
        Table.RenameColumns(#"Invoke Transform File", {"Name", "Source.Name"}),

    // 4. Keep only file name and transformed data
    #"Removed Other Columns" =
        Table.SelectColumns(#"Renamed Source Column", {"Source.Name", "Transform File"}),

    // 5. Expand all columns from transformed files
    #"Expanded Data Columns" =
        Table.ExpandTableColumn(
            #"Removed Other Columns",
            "Transform File",
            Table.ColumnNames(#"Transform File (3)"(#"Sample File (3)"))
        ),

    // 6. Explicitly remove all percentage columns (recalculated in model)
    #"Removed Percentage Columns" =
        Table.RemoveColumns(
            #"Expanded Data Columns",
            {
                "Nb sent / Nb targeted (%)",
                "Nb bounced / Nb targeted (%)",
                "Nb delivered / Nb sent (%)",
                "Nb opened / Nb delivered (%)",
                "Nb clicked / Nb delivered (%)",
                "Nb clicked / Nb opened (%)"
            }
        ),

    // 7. Set correct data types (counts only)
    #"Changed Type" =
        Table.TransformColumnTypes(
            #"Removed Percentage Columns",
            {
                {"Source.Name", type text},
                {"campaignId", Int64.Type},
                {"Sent date", type date},
                {"Campaign name", type text},
                {"Campaign Subjects", type text},
                {"SendingMode", type text},
                {"Nb targeted", Int64.Type},
                {"Nb sent", Int64.Type},
                {"Nb bounced", Int64.Type},
                {"Nb delivered", Int64.Type},
                {"Nb opened", Int64.Type},
                {"Nb clicked", Int64.Type},
                {"Nb error", Int64.Type},
                {"Nb filtered", Int64.Type},
                {"Nb unsubscribed", Int64.Type}
            }
        ),

    // 8. Remove SendingMode column
    #"Removed SendingMode" =
        Table.RemoveColumns(#"Changed Type", {"SendingMode"}),

    // 9. Rename columns to remove 'Nb ' prefix
    #"Renamed Nb Columns" =
        Table.RenameColumns(
            #"Removed SendingMode",
            {
                {"Nb targeted", "Targeted"},
                {"Nb sent", "Sent"},
                {"Nb bounced", "Bounced"},
                {"Nb delivered", "Delivered"},
                {"Nb opened", "Opened"},
                {"Nb clicked", "Clicked"},
                {"Nb error", "Error"},
                {"Nb filtered", "Filtered"},
                {"Nb unsubscribed", "Unsubscribed"}
            }
        ),

    // 10. Filter valid campaigns (exclude test/internal campaigns)
    #"Filtered Campaigns" =
        Table.SelectRows(
            #"Renamed Nb Columns",
            each
                Text.StartsWith([Campaign name], ValidCampaignPrefix, Comparer.OrdinalIgnoreCase)
                and not List.AnyTrue(
                    List.Transform(
                        ExclusionKeywords, // From config
                        (x) => Text.Contains([Campaign name], x, Comparer.OrdinalIgnoreCase)
                    )
                )
        ),

    // 11. Remove rows with no delivered emails
    #"Removed Invalid Campaigns" =
        Table.SelectRows(
            #"Filtered Campaigns",
            each [Delivered] <> null and [Delivered] > 0
        ),

    // 12. Remove technical column
    #"Removed Source Name" =
        Table.RemoveColumns(#"Removed Invalid Campaigns", {"Source.Name"})
in
    #"Removed Source Name"