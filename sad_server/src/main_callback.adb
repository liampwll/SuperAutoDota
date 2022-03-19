with Ada.Text_IO;
with Interfaces; use type Interfaces.Integer_64;
with AWS.Messages;
with AWS.Utils;
with Ada.Exceptions;
with AWS.Status;
use type AWS.Status.Request_Method;
with AWS.Server;
with Ada.Strings.Unbounded;
with GNATCOLL.SQL.Exec; use GNATCOLL.SQL.Exec;

package body Main_Callback is

   procedure Init is
      F : Forward_Cursor;
   begin
      GNAT.Random_Numbers.Reset (Random_Generator);
      Execute (DB, Q_Setup_Pragmas);
      for Round in Round_Number loop
         F.Fetch (DB, Q_Select_N_Teams_For_Round, Params => (1 => +Integer (Round), 2 => +50));
         while Has_Row (F) loop
            declare
               T : constant Team :=
                 (Steam_ID => Interfaces.Integer_64 (Bigint_Value (F, 0)),
                  Match_ID => Interfaces.Integer_64 (Bigint_Value (F, 1)),
                  Data => Team_Strings.To_Bounded_String (Value (F, 2)));
            begin
               Round_Teams (Round).Append (T);
            end;
            Next (F);
         end loop;
      end loop;
   end Init;

   function Handle_Request (Request : AWS.Status.Data) return AWS.Response.Data is
   begin
      declare
         URI             : constant String                    := AWS.Status.URI (Request);
         Method          : constant AWS.Status.Request_Method := AWS.Status.Method (Request);
         Steam_ID        : constant Interfaces.Integer_64     := Interfaces.Integer_64'Value (AWS.Status.Header (Request).Get ("SAD-SteamID"));
         Match_ID        : constant Interfaces.Integer_64     := Interfaces.Integer_64'Value (AWS.Status.Header (Request).Get ("SAD-MatchID"));
         Round           : constant Round_Number              := Round_Number'Value (AWS.Status.Header (Request).Get ("SAD-Round"));
         --  Auth_Header     : constant String                    := Aws.Status.Header (Request).Get ("SAD-Authorization");
      begin
         --  Ada.Text_IO.Put_Line ("Request to " & URI);
         if URI = "/ResumeData" then
            if Method = AWS.Status.GET then
               declare
                  F : Forward_Cursor;
               begin
                  F.Fetch (DB, Q_Select_Resume_Data, Params => (1 => As_Bigint (Long_Long_Integer (Steam_ID))));
                  if Has_Row (F) and not F.Is_Null (0) then
                     return AWS.Response.Build (Content_Type => "text/plain", Message_Body => (F.Value (0)));
                  else
                     return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S404);
                  end if;
               end;
            elsif Method = AWS.Status.POST then
               Execute (DB, Q_Replace_Player, Params => (1 => As_Bigint (Long_Long_Integer (Steam_ID)), 2 => +AWS.Status.Binary_Data (Request)));
               DB.Commit;
               return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S200);
            else
               return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S405);
            end if;
         elsif URI = "/EnemyForRound" then
            if Method = AWS.Status.GET then
               declare
                  Enemy_Team : constant Team := Round_Teams (Round).Get (Random_Natural (Gen => Random_Generator, Max => Round_Teams (Round).Capacity_Used - 1));
               begin
                  Execute (DB, Q_Insert_Round, Params =>
                             (1 => As_Bigint (Long_Long_Integer (Match_ID)),
                              2 => +Integer (Round),
                              3 => As_Bigint (Long_Long_Integer (Enemy_Team.Match_ID))));
                  return AWS.Response.Build
                    (Content_Type => "text/plain",
                     Message_Body => Team_Strings.To_String (Enemy_Team.Data));
               end;
            elsif Method = AWS.Status.POST then
               Execute (DB, Q_Complete_Round, Params =>
                          (1 => +AWS.Status.Binary_Data (Request),
                           2 => +Boolean'Value (AWS.Status.Header (Request).Get ("SAD-LastRoundWon")),
                           3 => As_Bigint (Long_Long_Integer (Match_ID)),
                           4 => +Integer (Round)));
               DB.Commit;
               declare
                  T : constant Team :=
                    (Steam_ID => Steam_ID,
                     Match_ID => Match_ID,
                     Data => Team_Strings.To_Bounded_String (Ada.Strings.Unbounded.To_String (AWS.Status.Binary_Data (Request))));
               begin
                  --  Don't put the same player in the buffer twice.
                  for I in 0 .. Round_Teams (Round).Capacity_Used - 1 loop
                     if Round_Teams (Round).Get (I).Steam_ID = Steam_ID then
                        Round_Teams (Round).Replace (I, T);
                        return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S200);
                     end if;
                  end loop;
                  Round_Teams (Round).Append (T);
                  return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S200);
               end;
            else
               return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S405);
            end if;
         elsif URI = "/NewGame" then
            if Method = AWS.Status.POST then
               Execute (DB, Q_Replace_Player, Params => (1 => As_Bigint (Long_Long_Integer (Steam_ID)), 2 => Null_Parameter));
               DB.Commit;
               declare
                  F : Forward_Cursor;
               begin
                  F.Fetch (DB, Q_Insert_Match_Return_ID, Params => (1 => As_Bigint (Long_Long_Integer (Steam_ID))));
                  return AWS.Response.Build (Content_Type => "text/plain", Message_Body => (F.Value (0)));
               end;
            else
               return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S405);
            end if;
         elsif URI = "/GameOver" then
            if Method = AWS.Status.POST then
               Execute (DB, Q_Replace_Player, Params => (1 => As_Bigint (Long_Long_Integer (Steam_ID)), 2 => Null_Parameter));
               DB.Commit;
               return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S200);
            else
               return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S405);
            end if;
         else
            return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S500);
         end if;
      end;
   exception
      when Error : Constraint_Error =>
         --  Log errors and continue in this case as it is likely better than killing the server no matter what.
         --  Just respond with 500 to any error since it is not visible to the user, even when the error is from the client, for example a bad round number.
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line (Ada.Exceptions.Exception_Information (Error));
         return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S500);
   end Handle_Request;

end Main_Callback;
