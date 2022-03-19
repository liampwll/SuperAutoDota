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

with Ada.Text_IO;
with AWS.Default;
with AWS.Server;
with AWS.Config;
with AWS.Services.Dispatchers.URI;
with Main_Callback;

procedure SAD_Server is
   Web_Server     : AWS.Server.HTTP;
   Web_Config     : constant AWS.Config.Object := AWS.Config.Get_Current;
   Web_Dispatcher : AWS.Services.Dispatchers.URI.Handler;
begin

   Ada.Text_IO.Put_Line ("Port: " & Natural'Image (AWS.Config.Server_Port (Web_Config)));
   Ada.Text_IO.Put_Line ("Admin URI: " & AWS.Config.Admin_URI (Web_Config));

   if AWS.Config.Max_Connection (Web_Config) /= 1 then
      Ada.Text_IO.Put_Line ("Max_Connection must be set to 1, this server is designed to run behind HAProxy and serve a single request at a time.");
      return;
   end if;

   Main_Callback.Init;

   AWS.Server.Start
     (Web_Server => Web_Server,
      Callback => Main_Callback.Handle_Request'Access,
      Config => Web_Config);

   AWS.Server.Wait (AWS.Server.Forever);
   AWS.Server.Shutdown (Web_Server);
end SAD_Server;
