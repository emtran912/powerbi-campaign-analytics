let
    Source = Folder.Files("C:\Users\etran\OneDrive - London Business School\Documents\Data\Quarterly Report\Quarterly campaign reports"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File", each #"Transform File"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File", Table.ColumnNames(#"Transform File"(#"Sample File"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",{
        {"Source.Name", type text}, 
        {"Campaign Name", type text}, 
        {"Delivered", Int64.Type}, 
        {"Opened", Int64.Type}, 
        {"Clicked", Int64.Type}, 
        {"Unsubscribed", Int64.Type}, 
        {"Delivered / (Sent)", type text}, 
        {"Opened / (Delivered)", type text}, 
        {"Clicked / (Opened)", type text}, 
        {"Clicked / (Delivered)", type text}, 
        {"Unsubscribed / (Delivered)", type text}
    }),

    // 1. Filter campaign names
    #"Filtered Campaigns" = Table.SelectRows(
        #"Changed Type",
        each 
            Text.StartsWith([Campaign Name], "ADV", Comparer.OrdinalIgnoreCase)
            and not List.AnyTrue(
                List.Transform(
                    {"staff", "internal", "ALT", "copy", "test", "faculty", "ballot", "emeritus"},
                    (x) => Text.Contains([Campaign Name], x, Comparer.OrdinalIgnoreCase)
                )
            )
    ),

    // 2. Extract last 10 characters as potential date string
    #"Added Date Text" = Table.AddColumn(
        #"Filtered Campaigns",
        "DateText",
        each Text.End([Campaign Name], 10),
        type text
    ),

    // 3. Try to parse date in multiple formats
    #"Added Date" = Table.AddColumn(
        #"Added Date Text",
        "Date",
        each 
            let
                txt = [DateText],
                d1 = try Date.From(DateTime.FromText(txt, "en-GB")),
                d2 = try Date.From(DateTime.FromText(Text.Replace(txt, ".", "/"), "en-GB")),
                d3 = try Date.From(DateTime.FromText(Text.Replace(txt, ".", "-"), "en-GB")),
                d4 = try Date.From(DateTime.FromText(txt)),
                d5 = try Date.From(DateTime.FromText(Text.Replace(txt, ".", "/"))),
                d6 = try Date.From(DateTime.FromText(Text.Replace(txt, ".", "-"))),
                result = List.First(
                    List.Select(
                        {d1, d2, d3, d4, d5, d6},
                        each _[HasError] = false
                    ),
                    null
                )
            in
                if result <> null then result[Value] else null,
        type date
    ),

    // 4. Remove rows where date extraction failed
    #"Filtered Valid Dates" = Table.SelectRows(
        #"Added Date",
        each [Date] <> null
    ),

    // 5. Remove helper column only
    #"Removed DateText" = Table.RemoveColumns(#"Filtered Valid Dates", {"DateText"}),

    // 6. Add Campaign Category
    #"Add Campaign Category" = Table.AddColumn(
        #"Removed DateText", 
        "Campaign Category", 
        each 
            if List.AnyTrue({
                    Text.Contains([Campaign Name], "PC Post-Email", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Appeal", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Mop-Up", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "60th Give", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Pledge", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Stewardship", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Phone Campaign", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "PC"),
                    Text.Contains([Campaign Name], "gift", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "donors", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "GG", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Global Give", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "GG25"),
                    Text.Contains([Campaign Name], "Phone Campaign", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "RC"),
                    Text.Contains([Campaign Name], "Thread"),
                    Text.Contains([Campaign Name], "Regent", Comparer.OrdinalIgnoreCase)
                }) 
            then "Appeal"
            else if Text.Contains([Campaign Name], "volunteer", Comparer.OrdinalIgnoreCase)
            then "Volunteer"
            else if Text.Contains([Campaign Name], "Welcome Alumni Community", Comparer.OrdinalIgnoreCase)
            then "Welcome emails"
            else if List.AnyTrue({
                    Text.Contains([Campaign Name], "R4NA", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Festival of Minds", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Events Newsletter", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "invitation", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "invite", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "event", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "WAC", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "reunion", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Middle East Conference", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "ME Conference", Comparer.OrdinalIgnoreCase)
                })
            then "Events"
            else if List.AnyTrue({
                    Text.Contains([Campaign Name], "rankings", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "FT", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Financial Times", Comparer.OrdinalIgnoreCase),
                    Text.Contains([Campaign Name], "Bloomberg", Comparer.OrdinalIgnoreCase)
                })
            then "Rankings"
            else if Text.Contains([Campaign Name], "Newsletter", Comparer.OrdinalIgnoreCase) and 
                    not Text.Contains([Campaign Name], "Events Newsletter", Comparer.OrdinalIgnoreCase)
            then "Alumni Newsletters"
            else "Other"
    ),

    // 7. Add New Alumni?
    #"New Alumni?" = Table.AddColumn(
        #"Add Campaign Category", 
        "New Alumni?", 
        each 
            if Text.Contains([Campaign Name], "R4NA", Comparer.OrdinalIgnoreCase) 
            then "Yes" 
            else if Text.Contains([Campaign Name], "FT rankings", Comparer.OrdinalIgnoreCase) 
            then "Yes" 
            else if Text.Contains([Campaign Name], "Welcome Alumni", Comparer.OrdinalIgnoreCase) 
            then "Yes" 
            else if Text.Contains([Campaign Name], "New Alumni", Comparer.OrdinalIgnoreCase) 
            then "Yes"
            else if Text.Contains([Campaign Name], "congregation", Comparer.OrdinalIgnoreCase)
            then "Yes"
            else "No"
    ),

    // 8. Convert all percentage columns from "95.4%" to decimal (0.954)
    PercentageColumns = {
        "Delivered / (Sent)",
        "Opened / (Delivered)",
        "Clicked / (Opened)",
        "Clicked / (Delivered)",
        "Unsubscribed / (Delivered)"
    },

    #"Converted Percentage Columns" = Table.TransformColumns(
        #"New Alumni?",
        List.Transform(
            PercentageColumns,
            (col) => {
                col,
                (val) => 
                    if val = null then null 
                    else Number.FromText(Text.TrimEnd(Text.Trim(Text.From(val)), "%")) / 100,
                type number
            }
        )
    ),

    // 9. Add Bounce Rate using converted Delivered / (Sent)
    #"Added Bounce Rate" = Table.AddColumn(
        #"Converted Percentage Columns",
        "Bounce Rate",
        each if [#"Delivered / (Sent)"] <> null then 1 - [#"Delivered / (Sent)"] else null,
        type number
    ),

    // 10. Remove rows where Delivered is null or <= 0
    #"Removed Old Campaigns" = Table.SelectRows(
        #"Added Bounce Rate",
        each ([Delivered] <> null and [Delivered] > 0)
    ),
    #"Add Campaign Key" = Table.AddColumn(
        #"Removed Old Campaigns", // Replace with your actual last step name
        "Campaign Key", 
        each Text.Remove(Text.Upper([Campaign Name]), {" ", "-", "."})
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
        {"Campaign Key", "Campaign Name", "Campaign Category"}
    )
in
    #"Remove Old Columns"