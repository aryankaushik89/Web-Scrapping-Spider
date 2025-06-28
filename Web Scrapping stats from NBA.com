"""
NBA Stats Scraper
-----------------
Scrapes NBA team and player stats from the NBA's stats API,
then saves as Excel files: one for teams, one for players, one with everything.
Good for quick analytics projects, dashboards, or just exploring real NBA data.
"""

import requests
import pandas as pd
import time

# NBA's team list endpoint (unofficial public JSON, no API key needed)
TEAM_URL = "https://stats.nba.com/stats/commonteamyears?LeagueID=00"
HEADERS = {
    "User-Agent": "Mozilla/5.0", # NBA.com blocks requests without this!
    "Referer": "https://www.nba.com/"
}

# Get all NBA team IDs for the current season
resp = requests.get(TEAM_URL, headers=HEADERS)
resp.raise_for_status()
years = resp.json()['resultSets'][0]['rowSet']

current_teams = []
for row in years:
    # row[1] = team ID, row[2] = min year, row[3] = max year
    if row[3] == 2024:  # Use latest season. Change as needed.
        current_teams.append({'TEAM_ID': row[1]})

print(f"Found {len(current_teams)} teams for 2024.")

# NBA team details (name, city, etc)
TEAM_DETAIL_URL = "https://stats.nba.com/stats/commonteamroster?TeamID={team_id}&Season=2023-24"
teams_full = []
players_all = []

for t in current_teams:
    team_id = t['TEAM_ID']
    url = TEAM_DETAIL_URL.format(team_id=team_id)
    # NBA.com blocks bots if you go too fast, so slow down a bit
    time.sleep(1)
    resp = requests.get(url, headers=HEADERS)
    if resp.status_code != 200:
        print(f"Could not fetch team {team_id}")
        continue
    data = resp.json()
    # Team info
    team_info = data['resultSets'][1]['rowSet'][0]
    team_cols = data['resultSets'][1]['headers']
    team_dict = dict(zip(team_cols, team_info))
    teams_full.append(team_dict)
    # Player info
    player_cols = data['resultSets'][0]['headers']
    for player_row in data['resultSets'][0]['rowSet']:
        player_dict = dict(zip(player_cols, player_row))
        player_dict['TEAM_ID'] = team_id  # link back to team
        players_all.append(player_dict)

# Save teams data
teams_df = pd.DataFrame(teams_full)
teams_df.to_excel("nba_teams_2023_24.xlsx", index=False)

# Save players data
players_df = pd.DataFrame(players_all)
players_df.to_excel("nba_players_2023_24.xlsx", index=False)

# Merge teams/players for full dataset
combined_df = pd.merge(players_df, teams_df, on="TEAM_ID", how="left", suffixes=('_player', '_team'))
combined_df.to_excel("nba_all_2023_24.xlsx", index=False)

print("Saved team info to nba_teams_2023_24.xlsx")
print("Saved player info to nba_players_2023_24.xlsx")
print("Saved merged dataset to nba_all_2023_24.xlsx")

"""
Summary:
- Scraped current NBA teams and full player rosters using the NBA's own JSON endpoints (no web scraping headaches)
- Stored team info, player info, and everything combined as Excel files, ready for analysis or reporting.
- These files let you build dashboards, run stats, or just explore the league fast. If you want advanced stats, switch to different NBA endpoints.
"""
