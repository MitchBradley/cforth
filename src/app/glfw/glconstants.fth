\ OpenGL constants

decimal

$0 constant GL_NONE
$0400 constant GL_FRONT_LEFT
$0401 constant GL_FRONT_RIGHT
$0402 constant GL_BACK_LEFT
$0403 constant GL_BACK_RIGHT
$0404 constant GL_FRONT
$0405 constant GL_BACK
$0406 constant GL_LEFT
$0407 constant GL_RIGHT
$0408 constant GL_FRONT_AND_BACK
$0409 constant GL_AUX0
$040A constant GL_AUX1
$040B constant GL_AUX2
$040C constant GL_AUX3

\ FrontFaceDirection
$0900 constant GL_CW
$0901 constant GL_CCW

$0B71 constant GL_DEPTH_TEST

$0CF5 constant GL_UNPACK_ALIGNMENT

$0DE1 constant GL_TEXTURE_2D

\ ShadingModel
$1D00 constant GL_FLAT
$1D01 constant GL_SMOOTH



$00000001 constant GL_CURRENT_BIT                    
$00000002 constant GL_POINT_BIT                      
$00000004 constant GL_LINE_BIT                       
$00000008 constant GL_POLYGON_BIT                    
$00000010 constant GL_POLYGON_STIPPLE_BIT            
$00000020 constant GL_PIXEL_MODE_BIT                 
$00000040 constant GL_LIGHTING_BIT                   
$00000080 constant GL_FOG_BIT                        
$00000100 constant GL_DEPTH_BUFFER_BIT               
$00000200 constant GL_ACCUM_BUFFER_BIT               
$00000400 constant GL_STENCIL_BUFFER_BIT             
$00000800 constant GL_VIEWPORT_BIT                   
$00001000 constant GL_TRANSFORM_BIT                  
$00002000 constant GL_ENABLE_BIT                     
$00004000 constant GL_COLOR_BUFFER_BIT               
$00008000 constant GL_HINT_BIT                       
$00010000 constant GL_EVAL_BIT                       
$00020000 constant GL_LIST_BIT                       
$00040000 constant GL_TEXTURE_BIT                    
$00080000 constant GL_SCISSOR_BIT                    
$000fffff constant GL_ALL_ATTRIB_BITS                

$1700 constant GL_MODELVIEW                      
$1701 constant GL_PROJECTION                     
$1702 constant GL_TEXTURE                        

\ PixelFormat
$1907 constant GL_RGB
$1908 constant GL_RGBA

$0000 constant GL_POINTS                         
$0001 constant GL_LINES                          
$0002 constant GL_LINE_LOOP                      
$0003 constant GL_LINE_STRIP                     
$0004 constant GL_TRIANGLES                      
$0005 constant GL_TRIANGLE_STRIP                 
$0006 constant GL_TRIANGLE_FAN                   
$0007 constant GL_QUADS                          
$0008 constant GL_QUAD_STRIP                     
$0009 constant GL_POLYGON                        

$88E4 constant GL_STATIC_DRAW
$8892 constant GL_ARRAY_BUFFER
$8893 constant GL_ELEMENT_ARRAY_BUFFER

$0B50 constant GL_LIGHTING
$0B51 constant GL_LIGHT_MODEL_LOCAL_VIEWER
$0B52 constant GL_LIGHT_MODEL_TWO_SIDE
$0B53 constant GL_LIGHT_MODEL_AMBIENT

$1200 constant GL_AMBIENT
$1201 constant GL_DIFFUSE
$1202 constant GL_SPECULAR
$1203 constant GL_POSITION
$1204 constant GL_SPOT_DIRECTION
$1205 constant GL_SPOT_EXPONENT
$1206 constant GL_SPOT_CUTOFF
$1207 constant GL_CONSTANT_ATTENUATION
$1208 constant GL_LINEAR_ATTENUATION
$1209 constant GL_QUADRATIC_ATTENUATION

$1400 constant GL_BYTE
$1401 constant GL_UNSIGNED_BYTE
$1402 constant GL_SHORT
$1403 constant GL_UNSIGNED_SHORT
$1404 constant GL_INT
$1405 constant GL_UNSIGNED_INT
$1406 constant GL_FLOAT
$1407 constant GL_2_BYTES
$1408 constant GL_3_BYTES
$1409 constant GL_4_BYTES
$140A constant GL_DOUBLE

$1600 constant GL_EMISSION
$1601 constant GL_SHININESS
$1602 constant GL_AMBIENT_AND_DIFFUSE
$1603 constant GL_COLOR_INDEXES

\ TextureMagFilter
$2600 constant GL_NEAREST
$2601 constant GL_LINEAR

\ TextureParameterName
$2800 constant GL_TEXTURE_MAG_FILTER
$2801 constant GL_TEXTURE_MIN_FILTER
$2802 constant GL_TEXTURE_WRAP_S
$2803 constant GL_TEXTURE_WRAP_T

$4000 constant GL_LIGHT0
$4001 constant GL_LIGHT1
$4002 constant GL_LIGHT2
$4003 constant GL_LIGHT3
$4004 constant GL_LIGHT4
$4005 constant GL_LIGHT5
$4006 constant GL_LIGHT6
$4007 constant GL_LIGHT7

$8074 constant GL_VERTEX_ARRAY
$8075 constant GL_NORMAL_ARRAY
$8076 constant GL_COLOR_ARRAY
$8077 constant GL_INDEX_ARRAY
$8078 constant GL_TEXTURE_COORD_ARRAY
$8079 constant GL_EDGE_FLAG_ARRAY
$807A constant GL_VERTEX_ARRAY_SIZE
$807B constant GL_VERTEX_ARRAY_TYPE
$807C constant GL_VERTEX_ARRAY_STRIDE
$807E constant GL_NORMAL_ARRAY_TYPE
$807F constant GL_NORMAL_ARRAY_STRIDE
$8081 constant GL_COLOR_ARRAY_SIZE
$8082 constant GL_COLOR_ARRAY_TYPE
$8083 constant GL_COLOR_ARRAY_STRIDE
$8085 constant GL_INDEX_ARRAY_TYPE
$8086 constant GL_INDEX_ARRAY_STRIDE
$8088 constant GL_TEXTURE_COORD_ARRAY_SIZE
$8089 constant GL_TEXTURE_COORD_ARRAY_TYPE
$808A constant GL_TEXTURE_COORD_ARRAY_STRIDE
$808C constant GL_EDGE_FLAG_ARRAY_STRIDE
$808E constant GL_VERTEX_ARRAY_POINTER
$808F constant GL_NORMAL_ARRAY_POINTER
$8090 constant GL_COLOR_ARRAY_POINTER
$8091 constant GL_INDEX_ARRAY_POINTER
$8092 constant GL_TEXTURE_COORD_ARRAY_POINTER
$8093 constant GL_EDGE_FLAG_ARRAY_POINTER

$812F constant GL_CLAMP_TO_EDGE

$2A20 constant GL_V2F
$2A21 constant GL_V3F
$2A22 constant GL_C4UB_V2F
$2A23 constant GL_C4UB_V3F
$2A24 constant GL_C3F_V3F
$2A25 constant GL_N3F_V3F
$2A26 constant GL_C4F_N3F_V3F
$2A27 constant GL_T2F_V3F
$2A28 constant GL_T4F_V4F
$2A29 constant GL_T2F_C4UB_V3F
$2A2A constant GL_T2F_C3F_V3F
$2A2B constant GL_T2F_N3F_V3F
$2A2C constant GL_T2F_C4F_N3F_V3F
$2A2D constant GL_T4F_C4F_N3F_V4F

$0200 constant GL_NEVER
$0201 constant GL_LESS
$0202 constant GL_EQUAL
$0203 constant GL_LEQUAL
$0204 constant GL_GREATER
$0205 constant GL_NOTEQUAL
$0206 constant GL_GEQUAL
$0207 constant GL_ALWAYS
