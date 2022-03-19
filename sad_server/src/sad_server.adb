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
