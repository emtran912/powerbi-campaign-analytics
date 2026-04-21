let
    Source = Sql.Database("SERVER_NAME", "DATABASE_NAME",
    [Query= " 
            SELECT DISTINCT
                per.recordid,
                per.field1           AS Field1,
                per.field2           AS Field2,
                per.field3           AS Field3,
                per.field4           AS Field4,
                prg.code             AS Code,
                prg.year             AS Year
            FROM table1 per
            LEFT JOIN table2 prg
                ON prg.recordid = per.recordid
            WHERE
                prg.status IN ('Status1', 'Status2')
                OR per.flag1 = 'Y'
                OR per.flag2 = 'Y'
            "]),
    #"Changed Type" = Table.TransformColumnTypes(
        Source,
        {
            {"recordid", Int64.Type},
            {"Field1", type text},
            {"Field2", type text},
            {"Field3", type text},
            {"Field4", type text},
            {"Code", type text},
            {"Year", Int64.Type}
        }
    ),
    #"Removed Duplicates" = Table.Distinct(#"Changed Type", {"recordid"})
in
    #"Removed Duplicates"