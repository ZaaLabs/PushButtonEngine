package com.pblabs.engine.util
{
    import com.pblabs.engine.math.Matrix3D;
    
    import flash.utils.ByteArray;

    public class ByteUtil
    {
        /**
         * Write a whole matrix.
         */ 
        public static function writeMatrix(m:Matrix3D, out:ByteArray):void
        {
            if(!m)
                throw new Error("You forgot the matrix!");

            out.writeFloat(m.n11);
            out.writeFloat(m.n12);
            out.writeFloat(m.n13);
            out.writeFloat(m.n14);
            
            out.writeFloat(m.n21);
            out.writeFloat(m.n22);
            out.writeFloat(m.n23);
            out.writeFloat(m.n24);
            
            out.writeFloat(m.n31);
            out.writeFloat(m.n32);
            out.writeFloat(m.n33);
            out.writeFloat(m.n34);
            
            out.writeFloat(m.n41);
            out.writeFloat(m.n42);
            out.writeFloat(m.n43);
            out.writeFloat(m.n44);
        }
        
        /**
         * Read a whole matrix.
         */ 
        public static function readMatrix(m:Matrix3D, out:ByteArray):void
        {
            if(!m)
                throw new Error("You forgot the matrix!");
            
            m.n11 = out.readFloat();
            m.n12 = out.readFloat();
            m.n13 = out.readFloat();
            m.n14 = out.readFloat();
            
            m.n21 = out.readFloat();
            m.n22 = out.readFloat();
            m.n23 = out.readFloat();
            m.n24 = out.readFloat();
            
            m.n31 = out.readFloat();
            m.n32 = out.readFloat();
            m.n33 = out.readFloat();
            m.n34 = out.readFloat();
            
            m.n41 = out.readFloat();
            m.n42 = out.readFloat();
            m.n43 = out.readFloat();
            m.n44 = out.readFloat();
        } 
    }
}