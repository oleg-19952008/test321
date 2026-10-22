package net.bigpoint.darkorbit.net
{
   public class CooldownCommandMap
   {
      
      private var mappedFunction:Function;
      
      private var serverCommands:Array;
      
      public function CooldownCommandMap(param1:Function, param2:Array)
      {
         super();
         this.mappedFunction = param1;
         this.serverCommands = param2;
      }
      
      public function callMappedFunction(param1:int) : void
      {
         var _loc2_:int = 0;
         while(_loc2_ < this.serverCommands.length)
         {
            this.mappedFunction(this.serverCommands[_loc2_],param1);
            _loc2_++;
         }
      }
   }
}

