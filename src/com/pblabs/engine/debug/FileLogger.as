package com.pblabs.engine.debug
{
    import com.pblabs.engine.debug.ILogAppender;
    
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    
    public class FileLogger implements ILogAppender
    {
        private var logFile:File;
        private var outputStream:FileStream;
        
        public function FileLogger(file:File)
        {
            logFile = file;
            
            outputStream = new FileStream();
            outputStream.open(logFile, FileMode.WRITE);
        }
        
        public function addLogMessage(level:String, loggerName:String, message:String):void
        {
            outputStream.writeUTFBytes(level + ": " + loggerName + " - " + message+"\n");
        }
    }
}