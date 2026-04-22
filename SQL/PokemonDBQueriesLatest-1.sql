/* 1) Compare legendary and non-legendary Pokémon by calculating the average value of each main battle stat (HP, Attack, Defense, Special Attack, Special Defense, and Speed). 
Additionally, include an overall summary row for all Pokémon using ROLLUP, labeled as 'All Pokemon'. */

SELECT
    CASE 
        WHEN p.Is_Legendary = 1 THEN 'Legendary'
        WHEN p.Is_Legendary = 0 THEN 'Non-Legendary'
        ELSE 'All Pokemon'
    END AS Pokemon_Category,
    AVG(ps.HP * 1.0) AS Avg_HP,
    AVG(ps.Attack * 1.0) AS Avg_Attack,
    AVG(ps.Defense * 1.0) AS Avg_Defense,
    AVG(ps.Sp_Attack * 1.0) AS Avg_Sp_Attack,
    AVG(ps.Sp_Defense * 1.0) AS Avg_Sp_Defense,
    AVG(ps.Speed * 1.0) AS Avg_Speed
FROM Pokemon p
JOIN Pokemon_Stats ps
    ON p.Pokemon_Id = ps.Pokemon_Id
GROUP BY ROLLUP (p.Is_Legendary);


/* 2) Compare legendary and non-legendary Pokémon by calculating the average total base stats (sum of all six battle stats) and the average trading card price. 
This helps evaluate the relationship between overall battle strength and card market value across the two groups. */

SELECT
    CASE WHEN p.Is_Legendary = 1 THEN 'Legendary' ELSE 'Non-Legendary' END AS Pokemon_Category,
    AVG((ps.HP + ps.Attack + ps.Defense + ps.Sp_Attack + ps.Sp_Defense + ps.Speed) * 1.0) AS Avg_Total_Stats,
    AVG(pc.Recent_Price_USD) AS Avg_Card_Price
FROM Pokemon p
JOIN Pokemon_Stats ps
    ON p.Pokemon_Id = ps.Pokemon_Id
JOIN Pokemon_Cards pc
    ON p.Pokemon_Id = pc.Pokemon_Id
GROUP BY p.Is_Legendary;


/* 3) Identify the strongest Pokémon in each category (legendary vs. non-legendary) based on total base stats. 
For each group, return the Pokémon(s) with the maximum total stats along with their primary type, allowing comparison of top performers between the two categories. */

SELECT
    CASE WHEN p.Is_Legendary = 1 THEN 'Legendary' ELSE 'Non-Legendary' END AS Pokemon_Category,
    p.Pokemon_Name,
    t.Type_Name AS Primary_Type,
    (ps.HP + ps.Attack + ps.Defense + ps.Sp_Attack + ps.Sp_Defense + ps.Speed) AS Total_Stats
FROM Pokemon p
JOIN Pokemon_Stats ps
    ON p.Pokemon_Id = ps.Pokemon_Id
JOIN Pokemon_Types pt
    ON p.Pokemon_Id = pt.Pokemon_Id
   AND pt.Type_Slot = 1
JOIN Types t
    ON pt.Type_Id = t.Type_Id
WHERE (ps.HP + ps.Attack + ps.Defense + ps.Sp_Attack + ps.Sp_Defense + ps.Speed) IN (
    SELECT MAX(ps2.HP + ps2.Attack + ps2.Defense + ps2.Sp_Attack + ps2.Sp_Defense + ps2.Speed)
    FROM Pokemon p2
    JOIN Pokemon_Stats ps2
        ON p2.Pokemon_Id = ps2.Pokemon_Id
    WHERE p2.Is_Legendary = p.Is_Legendary
)
ORDER BY Pokemon_Category, p.Pokemon_Name;


/* 4) Analyze Pokémon types by counting how many legendary and non-legendary Pokémon belong to each type. 
Only include types that have at least 5 legendary Pokémon and at least 40 non-legendary Pokémon.
Results are sorted by the number of legendary Pokémon (descending), then by non-legendary counts. */

SELECT
    t.Type_Name,
    SUM(CASE WHEN p.Is_Legendary = 1 THEN 1 ELSE 0 END) AS Legendary_Type_Rows,
    SUM(CASE WHEN p.Is_Legendary = 0 THEN 1 ELSE 0 END) AS NonLegendary_Type_Rows
FROM Pokemon p
JOIN Pokemon_Types pt
    ON p.Pokemon_Id = pt.Pokemon_Id
JOIN Types t
    ON pt.Type_Id = t.Type_Id
GROUP BY t.Type_Name
HAVING SUM(CASE WHEN p.Is_Legendary = 1 THEN 1 ELSE 0 END) >= 5
   AND SUM(CASE WHEN p.Is_Legendary = 0 THEN 1 ELSE 0 END) >= 40
ORDER BY Legendary_Type_Rows DESC, NonLegendary_Type_Rows DESC;


/* 5) Compare legendary and non-legendary Pokémon by grouping them based on how many types each Pokémon has (e.g., single-type vs dual-type). 
Count how many Pokémon fall into each type-count category for both groups, and sort the results by category and number of types. */

SELECT
    CASE WHEN p.Is_Legendary = 1 THEN 'Legendary' ELSE 'Non-Legendary' END AS Pokemon_Category,
    tc.Type_Count,
    COUNT(*) AS Pokemon_Count
FROM Pokemon p
JOIN (
    SELECT
        Pokemon_Id,
        COUNT(*) AS Type_Count
    FROM Pokemon_Types
    GROUP BY Pokemon_Id
) tc
    ON p.Pokemon_Id = tc.Pokemon_Id
GROUP BY p.Is_Legendary, tc.Type_Count
ORDER BY Pokemon_Category, tc.Type_Count;


/* 6) Compare legendary and non-legendary Pokémon by calculating the average number of total abilities and hidden abilities per Pokémon. 
This highlights differences in ability distribution between the two groups. */

SELECT
    CASE WHEN p.Is_Legendary = 1 THEN 'Legendary' ELSE 'Non-Legendary' END AS Pokemon_Category,
    AVG(a.Ability_Count * 1.0) AS Avg_Ability_Count,
    AVG(a.Hidden_Ability_Count * 1.0) AS Avg_Hidden_Ability_Count
FROM Pokemon p
JOIN (
    SELECT
        Pokemon_Id,
        COUNT(*) AS Ability_Count,
        SUM(CASE WHEN Is_Hidden = 1 THEN 1 ELSE 0 END) AS Hidden_Ability_Count
    FROM Pokemon_Abilities
    GROUP BY Pokemon_Id
) a
    ON p.Pokemon_Id = a.Pokemon_Id
GROUP BY p.Is_Legendary;


/* 7) Analyze Pokémon egg groups by counting the number of distinct legendary and non-legendary Pokémon in each group. 
This highlights how breeding classifications differ between the two categories. */

SELECT
    eg.Egg_Group_Name,
    COUNT(DISTINCT CASE WHEN p.Is_Legendary = 0 THEN peg.Pokemon_Id END) AS NonLegendary_Count,
    COUNT(DISTINCT CASE WHEN p.Is_Legendary = 1 THEN peg.Pokemon_Id END) AS Legendary_Count
FROM Pokemon p
JOIN Pokemon_Egg_Groups peg
    ON p.Pokemon_Id = peg.Pokemon_Id
JOIN Egg_Groups eg
    ON peg.Egg_Group_Id = eg.Egg_Group_Id
GROUP BY eg.Egg_Group_Name
ORDER BY NonLegendary_Count DESC;


/* 8) Provide a detailed follow-up to the egg group analysis by listing all legendary Pokémon along with their associated egg groups. 
Uses LEFT JOINs to ensure all legendary Pokémon are included, even if they do not belong to any egg group. */

SELECT
    p.Pokemon_Name,
    p.Is_Legendary,
    eg.Egg_Group_Name
FROM Pokemon p
LEFT JOIN Pokemon_Egg_Groups peg
    ON p.Pokemon_Id = peg.Pokemon_Id
LEFT JOIN Egg_Groups eg
    ON peg.Egg_Group_Id = eg.Egg_Group_Id
WHERE p.Is_Legendary = 1;


/* 9) Compare legendary and non-legendary Pokémon by analyzing their trading card distributions. 
Count the number of cards and calculate the average card price for each rarity level within both groups, with results ordered by category and highest average card price. */

SELECT
    CASE WHEN p.Is_Legendary = 1 THEN 'Legendary' ELSE 'Non-Legendary' END AS Pokemon_Category,
    cr.Card_Rarity_Name,
    COUNT(*) AS Card_Count,
    AVG(pc.Recent_Price_USD) AS Avg_Card_Price
FROM Pokemon_Cards pc
JOIN Pokemon p
    ON pc.Pokemon_Id = p.Pokemon_Id
JOIN Card_Rarities cr
    ON pc.Card_Rarity_Id = cr.Card_Rarity_Id
GROUP BY p.Is_Legendary, cr.Card_Rarity_Name
ORDER BY Pokemon_Category, Avg_Card_Price DESC;


/* 10) Calculate the average trading card price for both legendary and non-legendary Pokémon using variables. 
Then, identify legendary Pokémon whose card prices are above the legendary average, displaying their individual prices alongside both group averages, sorted from highest to lowest price. */

DECLARE @LegendaryAvgPrice DECIMAL(10,2);
DECLARE @Non_LegendaryAvgPrice DECIMAL(10,2);

-- Avg for legendary
SELECT @LegendaryAvgPrice = AVG(pc.Recent_Price_USD)
FROM Pokemon_Cards pc
JOIN Pokemon p
    ON pc.Pokemon_Id = p.Pokemon_Id
WHERE p.Is_Legendary = 1;

-- Avg for non legendary
SELECT @Non_LegendaryAvgPrice = AVG(pc.Recent_Price_USD)
FROM Pokemon_Cards pc
JOIN Pokemon p
    ON pc.Pokemon_Id = p.Pokemon_Id
WHERE p.Is_Legendary = 0;

SELECT
    p.Pokemon_Name,
    p.Is_Legendary,
    pc.Recent_Price_USD,
    @LegendaryAvgPrice AS Legendary_Avg_Card_Price,
    @Non_LegendaryAvgPrice AS NonLegendary_Avg_Card_Price
FROM Pokemon_Cards pc
JOIN Pokemon p
    ON pc.Pokemon_Id = p.Pokemon_Id
WHERE pc.Recent_Price_USD > @LegendaryAvgPrice
AND pc.Recent_Price_USD > @Non_LegendaryAvgPrice
ORDER BY p.Is_Legendary, pc.Recent_Price_USD DESC;


/* 11) Compare legendary and non-legendary Pokémon by analyzing the average value of higher-tier trading card rarities. 
Excludes common and standard rarity levels to focus on premium cards where both legendary and non-legendary are present, grouping results by rarity and category, and sorting by average value. */

SELECT p.Is_Legendary,
       cr.Card_Rarity_Name,
       AVG(pc.Recent_Price_USD) AS Avg_Value
FROM Pokemon p
JOIN Pokemon_Cards pc ON p.Pokemon_Id = pc.Pokemon_Id
JOIN Card_Rarities cr ON pc.Card_Rarity_Id = cr.Card_Rarity_Id
WHERE Card_Rarity_Name NOT LIKE 'Common' AND Card_Rarity_Name NOT LIKE 'Uncommon' AND Card_Rarity_Name NOT LIKE 'Rare' AND Card_Rarity_Name NOT LIKE 'Holo Rare' AND Card_Rarity_Name NOT LIKE 'Illustration Rare'
GROUP BY p.Is_Legendary, cr.Card_Rarity_Name
ORDER BY Avg_Value; 


/* 12) Use a CTE to compute total stats per Pokémon, then return only those whose total stats exceed the overall average, ordered from highest to lowest. */
WITH Total_Stats AS (
    SELECT 
        p.Pokemon_Id,
        p.Pokemon_Name,
        (ps.HP + ps.Attack + ps.Defense + ps.Sp_Attack + ps.Sp_Defense + ps.Speed) AS Total_Stats
    FROM Pokemon_Stats ps
    JOIN Pokemon p 
        ON ps.Pokemon_Id = p.Pokemon_Id
)
SELECT *
FROM Total_Stats
WHERE Total_Stats > (SELECT AVG(Total_Stats * 1.0) FROM Total_Stats)
ORDER BY Total_Stats DESC;


/* STORED PROCEDURE WITH IF / ELSE: Create and execute a stored procedure (sp_GetPokemonCardAnalysis) that accepts a category parameter ('Legendary', 'Non-Legendary', or 'Summary').
Based on the input, it either returns the top 15 highest-priced Pokémon cards for the selected group or provides summary statistics (average, minimum, and maximum card prices) for both groups. */

DROP PROCEDURE IF EXISTS sp_GetPokemonCardAnalysis
GO

CREATE PROCEDURE sp_GetPokemonCardAnalysis
    @Category VARCHAR(20)
AS
BEGIN

    IF @Category = 'Legendary'
    BEGIN
        SELECT TOP 15
            p.Pokemon_Name,
            cs.Card_Set_Name,
            cr.Card_Rarity_Name,
            pc.Recent_Price_USD
        FROM Pokemon_Cards pc
        JOIN Pokemon p
            ON pc.Pokemon_Id = p.Pokemon_Id
        JOIN Card_Sets cs
            ON pc.Card_Set_Id = cs.Card_Set_Id
        JOIN Card_Rarities cr
            ON pc.Card_Rarity_Id = cr.Card_Rarity_Id
        WHERE p.Is_Legendary = 1
        ORDER BY pc.Recent_Price_USD DESC;
    END
    ELSE IF @Category = 'Non-Legendary'
    BEGIN
        SELECT TOP 15
            p.Pokemon_Name,
            cs.Card_Set_Name,
            cr.Card_Rarity_Name,
            pc.Recent_Price_USD
        FROM Pokemon_Cards pc
        JOIN Pokemon p
            ON pc.Pokemon_Id = p.Pokemon_Id
        JOIN Card_Sets cs
            ON pc.Card_Set_Id = cs.Card_Set_Id
        JOIN Card_Rarities cr
            ON pc.Card_Rarity_Id = cr.Card_Rarity_Id
        WHERE p.Is_Legendary = 0
        ORDER BY pc.Recent_Price_USD DESC;
    END
    ELSE
    BEGIN
        SELECT
            CASE WHEN p.Is_Legendary = 1 THEN 'Legendary' ELSE 'Non-Legendary' END AS Pokemon_Category,
            CAST(AVG(pc.Recent_Price_USD) AS DECIMAL(10,2)) AS Avg_Card_Price,
            CAST(MIN(pc.Recent_Price_USD) AS DECIMAL(10,2)) AS Min_Card_Price,
            CAST(MAX(pc.Recent_Price_USD) AS DECIMAL(10,2)) AS Max_Card_Price
        FROM Pokemon_Cards pc
        JOIN Pokemon p
            ON pc.Pokemon_Id = p.Pokemon_Id
        GROUP BY p.Is_Legendary;
    END
END;
GO

EXEC sp_GetPokemonCardAnalysis @Category = 'Legendary';
EXEC sp_GetPokemonCardAnalysis @Category = 'Non-Legendary';
EXEC sp_GetPokemonCardAnalysis @Category = 'Summary';


/* VIEW: Create a reusable view (vw_PokemonBattleProfile) that combines Pokémon information with their battle stats and calculates total stats. */

DROP VIEW IF EXISTS vw_PokemonBattleProfile;
GO

CREATE VIEW vw_PokemonBattleProfile AS
SELECT
    p.Pokemon_Id,
    p.Pokemon_Name,
    p.Is_Legendary,
    ps.HP,
    ps.Attack,
    ps.Defense,
    ps.Sp_Attack,
    ps.Sp_Defense,
    ps.Speed,
    (ps.HP + ps.Attack + ps.Defense + ps.Sp_Attack + ps.Sp_Defense + ps.Speed) AS Total_Stats
FROM Pokemon p
JOIN Pokemon_Stats ps
    ON p.Pokemon_Id = ps.Pokemon_Id;
GO

--Query the view which displays each Pokémon’s stats, total strength, and legendary status in a single easy to query dataset
SELECT *
FROM vw_PokemonBattleProfile


/* 13) Integrated query: Use this view to retrieve the top 10 Pokémon with the highest total stats, including whether each is legendary, simplifying and reusing logic for strength-based comparisons. */

SELECT TOP 10
    v.Pokemon_Name,
    v.Total_Stats,
    v.Is_Legendary
FROM vw_PokemonBattleProfile v
ORDER BY v.Total_Stats DESC, v.Pokemon_Name;


/* 14) Integrated query: Use the vw_PokemonBattleProfile view to compare legendary and non-legendary Pokémon by counting how many Pokémon are in each category and calculating the average total stats for each group. 
This provides a summary of both population size and overall battle strength. */

SELECT
    CASE WHEN v.Is_Legendary = 1 THEN 'Legendary' ELSE 'Non-Legendary' END AS Pokemon_Category,
    COUNT(*) AS Pokemon_Count,
    AVG(v.Total_Stats * 1.0) AS Avg_Total_Stats
FROM vw_PokemonBattleProfile v
GROUP BY v.Is_Legendary;


/* FURTHER ANALYSIS WITH GENAI: Rank Pokémon cards within legendary and non-legendary groups based on their recent price using a window function. 
Then, retrieve the top 10 highest- priced cards from each category, ordered by category and rank. */

WITH RankedCards AS (
    SELECT
        CASE WHEN p.Is_Legendary = 1 THEN 'Legendary' ELSE 'Non-Legendary' END AS Pokemon_Category,
        p.Pokemon_Name,
        pc.Recent_Price_USD,
        ROW_NUMBER() OVER (
            PARTITION BY p.Is_Legendary
            ORDER BY pc.Recent_Price_USD DESC, p.Pokemon_Name
        ) AS Price_Rank
    FROM Pokemon_Cards pc
    JOIN Pokemon p
        ON pc.Pokemon_Id = p.Pokemon_Id
)
SELECT
    Pokemon_Category,
    Pokemon_Name,
    Recent_Price_USD,
    Price_Rank
FROM RankedCards
WHERE Price_Rank <= 10
ORDER BY Pokemon_Category, Price_Rank;

