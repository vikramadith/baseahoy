package com.baseahoy.utils
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	public class FileUtil
	{
		public static function getFileContents(file:File):String
		{
			// Read contents of the file
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);
			
			var fileContent:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
			fileStream.close();
			
			return fileContent;
		}
		
		public static function getFileNameWithoutExtention(file:File):String
		{
			var fileNameRegExp:RegExp = /^(?P<fileName>.*)\..*$/;
			return fileNameRegExp.exec(file.name).fileName;	
		}
		
		public static function saveFile(text:String, file:File):void
		{ 
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(text);
			fs.close(); 
		}
	}
}