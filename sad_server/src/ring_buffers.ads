generic
   type Element_Type is private;
package Ring_Buffers is

   type Ring_Buffer (Capacity_In : Positive) is tagged private;

   procedure Append (R : in out Ring_Buffer; Element : Element_Type);
   function Get (R : Ring_Buffer; I: Natural) return Element_Type;
   procedure Replace (R : in out Ring_Buffer; I: Natural; Element : Element_Type);
   function Capacity_Used (R : Ring_Buffer) return Natural;

   Invalid_Index : exception;

private
   type Element_Array is array (Natural range <>) of Element_Type;
   type Ring_Buffer (Capacity_In: Positive) is tagged record
      Elements    : Element_Array (1 .. Capacity_In);
      Is_Full     : Boolean        := False;
      Current_End : Natural        := 0; -- Offset by one, initial first index is actually 1.
      Capacity    : Positive       := Capacity_In;
   end record;
end Ring_Buffers;