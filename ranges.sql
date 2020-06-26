DROP DATABASE IF EXISTS overlapping_ranges;
CREATE DATABASE overlapping_ranges;
USE overlapping_ranges;


CREATE TABLE OfficeStay (
    Id INT NOT NULL AUTO_INCREMENT,
    UserId INT NOT NULL,
    TimeEntered INT NOT NULL,
    TimeLeft INT NOT NULL,
    PRIMARY KEY (Id)
);


INSERT INTO OfficeStay (UserId, TimeEntered, TimeLeft) VALUES
-- First day
(1, 0, 6),
(2, 3, 9),
(1, 12, 14),
-- Second day
(1, 101, 105),
(2, 104, 110),
(1, 106, 120),
-- Third day
(1, 203, 214),
(2, 205, 206),
(3, 209, 211);

WITH RangesWithRangeIds AS (
    WITH SubsequentOverlappingRanges AS (
        WITH OverlappingRanges AS (
            SELECT
                o1.TimeEntered as StartTime,
                MAX(GREATEST(o1.TimeLeft, o2.TimeLeft)) as EndTime
            -- Join to the same table in order to find all ranges that overlap (including self-overlaps)
            FROM OfficeStay as o1
            JOIN OfficeStay as o2 ON
                -- This condition checks if two ranges overlap
                o1.TimeEntered <= o2.TimeLeft AND o2.TimeEntered <= o1.TimeLeft
            GROUP BY StartTime
        )
        SELECT
            StartTime,
            EndTime,
            -- 1 indicates when new range starts
            -- 0 indicates that row should be included into same range as previous range
            IFNULL((StartTime - LAG(EndTime, 1) OVER (ORDER BY StartTime)) > 0, 0) as DoesOverlapWithPrevRow
        FROM OverlappingRanges
    )
    SELECT
        StartTime,
        EndTime,
        -- Cumulative sum
        --   +1 when new range starts (range that doesn't overlap with range in the previous row)
        --   +0 when range remains unchanged
        SUM(DoesOverlapWithPrevRow) OVER (ORDER BY StartTime) as RangeId
    FROM SubsequentOverlappingRanges
)
SELECT
    MIN(StartTime) as StartTime,
    MAX(EndTime) as EndTime,
    RangeId
FROM RangesWithRangeIds
GROUP BY RangeId;
