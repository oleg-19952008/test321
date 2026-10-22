package net.bigpoint.darkorbit.net
{
   import net.bigpoint.darkorbit.Main;
   
   public class BaseAssembly
   {
      
      protected static var _main:Main;
      
      public function BaseAssembly()
      {
         super();
      }
      
      public static function setMain(param1:Main) : void
      {
         _main = param1;
      }
   }
}

