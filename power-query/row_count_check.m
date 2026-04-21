let
    // Reference both queries
    Stg = stg_email_clicks,
    Fact = fact_email_clicks,

    // Create a small comparison table
    RowCountComparison =
        #table(
            {"Table Name", "Row Count"},
            {
                {"stg_email_clicks", Table.RowCount(Stg)},
                {"fact_email_clicks", Table.RowCount(Fact)}
            }
        )
in
    RowCountComparison