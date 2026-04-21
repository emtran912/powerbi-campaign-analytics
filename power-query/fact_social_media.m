let
    Source = Folder.Files("path"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File (2)", each #"Transform File (2)"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File (2)"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File (2)", Table.ColumnNames(#"Transform File (2)"(#"Sample File (2)"))),
    #"Changed Type" =
        Table.TransformColumnTypes(
            #"Expanded Table Column1",
            {
                {"Source.Name", type text},
                {"Date", type text},
                {"Post ID", type text},
                {"Network", type text},
                {"Post Type", type text},
                {"Content Type", type text},
                {"Profile", type text},
                {"Sent by", type text},
                {"Link", type text},
                {"Post", type text},
                {"Linked Content", type text},
                {"Impressions", Int64.Type},
                {"Engagement Rate (per Impression)", Percentage.Type},
                {"Engagements", Int64.Type},
                {"Reactions", Int64.Type},
                {"Comments", Int64.Type},
                {"Shares", Int64.Type},
                {"Saves", Int64.Type},
                {"Post Link Clicks", Int64.Type},
                {"Other Engagements", Int64.Type},
                {"Video Views", Int64.Type},
                {"Reach", Int64.Type},
                {"Post Clicks (All)", Int64.Type},
                {"Click-Through Rate", Percentage.Type},
                {"Follows from Post", type any},
                {"Unfollows from Post", type any},
                {"Average Video Time Watched (Seconds)", type any},
                {"Unique Full Video Views", type any},
                {"Unique Video Views", type any},
                {"Video View Time (Seconds)", type any},
                {"95% Video Views", type any},
                {"Click to Play Full Video Views", type any},
                {"Full Video Views", type any},
                {"Tags", type text}
            }
        ),

    #"Trimmed Date" =
        Table.TransformColumns(
            #"Changed Type",
            {{"Date", each Text.Trim(_), type text}}
        ),

    // ------------------------------------------------------------------
    // Parse datetime text safely and return DATE only
    // ------------------------------------------------------------------
    #"Converted Date" =
        Table.TransformColumns(
            #"Trimmed Date",
            {
                {
                    "Date",
                    each
                        try DateTime.Date(DateTime.FromText(_, "en-US"))
                        otherwise null,
                    type date
                }
            }
        ),

    #"Removed Duplicates" =
        Table.Distinct(#"Converted Date", {"Post ID"}),

    #"Removed Columns" =
        Table.RemoveColumns(
            #"Removed Duplicates",
            {"Profile", "Sent by"}
        ),

    NumericColumns = {
        "Impressions", "Engagements", "Reactions", "Comments", "Shares", "Saves",
        "Post Link Clicks", "Other Engagements", "Video Views", "Reach",
        "Post Clicks (All)"
    },

    #"Removed All Null Numeric Rows" =
        Table.SelectRows(
            #"Removed Columns",
            each
                List.NonNullCount(
                    List.Transform(
                        NumericColumns,
                        (col) => Record.Field(_, col)
                    )
                ) > 0
        )
in
    #"Removed All Null Numeric Rows"