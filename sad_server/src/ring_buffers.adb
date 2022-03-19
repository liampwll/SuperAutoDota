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
