package body Counters is

   function Next (C : in out Counter) return T is
   begin
      if (C.Is_First) then
         C.Is_First := False;
      else
         C.Current := T'Succ (C.Current);
      end if;
      return C.Current;
   end Next;

end Counters;