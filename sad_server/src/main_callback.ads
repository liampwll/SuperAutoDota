--  Copyright (C) 2022 Liam Powell
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

with AWS.Response;
with AWS.Status;
with Ring_Buffers;
with Ada.Strings.Bounded;
with Ada.Containers.Vectors;
with GNATCOLL.SQL.Sqlite;
with GNATCOLL.SQL.Exec;
with GNATCOLL.SQL;
with GNAT.Random_Numbers;
with Interfaces;

package Main_Callback is

   procedure Init;

   function Handle_Request (Request : AWS.Status.Data) return AWS.Response.Data;

private
   --  I suppose we could keep going past 2000 and not keep those high rounds in memory, but no one is going to reach round 2000.
   type Round_Number is range 0 .. 2000;
   package Team_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 2_000);

   type Team is record
      Steam_ID : Interfaces.Integer_64;
      Match_ID : Interfaces.Integer_64;
      Data     : Team_Strings.Bounded_String;
   end record;

   package Team_String_Ring_Buffers is new Ring_Buffers (Element_Type => Team);

   Round_Teams : array (Round_Number) of access Team_String_Ring_Buffers.Ring_Buffer :=
     (Round_Number'First .. 200 => new Team_String_Ring_Buffers.Ring_Buffer (50),
      others                    => new Team_String_Ring_Buffers.Ring_Buffer (10));

   DB_Description : GNATCOLL.SQL.Exec.Database_Description := GNATCOLL.SQL.Sqlite.Setup (Database => "sad_db.sqlite3");
   DB : GNATCOLL.SQL.Exec.Database_Connection := DB_Description.Build_Connection;

   Q_Replace_Player : constant GNATCOLL.SQL.Exec.Prepared_Statement := GNATCOLL.SQL.Exec.Prepare
     ("INSERT OR REPLACE INTO players (steam_id, resume_data) VALUES ($1, $2);",
      On_Server => True);

   Q_Select_Resume_Data : constant GNATCOLL.SQL.Exec.Prepared_Statement := GNATCOLL.SQL.Exec.Prepare
     ("SELECT resume_data FROM players WHERE steam_id = $1;",
      On_Server => True);

   Q_Insert_Match_Return_ID : constant GNATCOLL.SQL.Exec.Prepared_Statement := GNATCOLL.SQL.Exec.Prepare
     ("INSERT INTO matches (steam_id) VALUES ($1) RETURNING match_id;",
      On_Server => True);

   Q_Select_N_Teams_For_Round : constant GNATCOLL.SQL.Exec.Prepared_Statement := GNATCOLL.SQL.Exec.Prepare
     ("SELECT steam_id, match_id, team_data " &
      "FROM (SELECT * " &
      "      FROM rounds " &
      "      JOIN matches " &
      "      ON rounds.match_id = matches.match_id " &
      "      WHERE rounds.round_num = $1 " &
      "      AND rounds.team_data IS NOT NULL " &
      "      GROUP BY matches.steam_id " &
      "      HAVING MAX(rounds.timestamp) " &
      "      ORDER BY rounds.timestamp DESC " &
      "      LIMIT $2) x " &
      "ORDER BY timestamp ASC;",
      On_Server => False);

   Q_Insert_Round : constant GNATCOLL.SQL.Exec.Prepared_Statement := GNATCOLL.SQL.Exec.Prepare
     ("INSERT INTO rounds (match_id, round_num, enemy_match_id) VALUES ($1, $2, $3);",
      On_Server => True);

   Q_Complete_Round : constant GNATCOLL.SQL.Exec.Prepared_Statement := GNATCOLL.SQL.Exec.Prepare
     ("UPDATE rounds SET team_data = $1, won = $2 where match_id = $3 AND round_num = $4;",
      On_Server => True);

   Q_Setup_Pragmas : constant GNATCOLL.SQL.Exec.Prepared_Statement := GNATCOLL.SQL.Exec.Prepare
     ("PRAGMA soft_heap_limit=134217728;",
      On_Server => False);

   Random_Generator : GNAT.Random_Numbers.Generator;
   function Random_Natural is new GNAT.Random_Numbers.Random_Discrete (Natural);
end Main_Callback;
