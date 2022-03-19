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
