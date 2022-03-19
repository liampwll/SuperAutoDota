package body Ring_Buffers is

   procedure Append (R : in out Ring_Buffer; Element : Element_Type) is
   begin
      R.Elements (R.Current_End + 1) := Element;
      R.Current_End := R.Current_End + 1;
      if R.Current_End = R.Capacity then
         R.Current_End := 0;
         R.Is_Full := True;
      end if;
   end Append;

   function Get (R : in Ring_Buffer; I : Natural) return Element_Type is
   begin
      if I >= R.Capacity_Used then
         raise Invalid_Index;
      end if;
      return R.Elements (I + 1);
   end Get;

   procedure Replace (R : in out Ring_Buffer; I: Natural; Element : Element_Type) is
   begin
      if I >= R.Capacity_Used then
         raise Invalid_Index;
      end if;
      R.Elements (I + 1) := Element;
   end Replace;

   function Capacity_Used (R : in Ring_Buffer) return Natural is (if R.Is_Full then R.Capacity else R.Current_End);
end Ring_Buffers;