const sampler_t sampler =
    CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;

#define DIM 2
#if DIM==3

#define IMG_T image3d_t
#define GID_T int3
#define INIT_GID(gid) GID_T gid; gid = (GID_T)(get_global_id(0), get_global_id(1), get_global_id(2));

#else
#define IMG_T image2d_t
#define GID_T int2
#define INIT_GID(gid) GID_T gid; gid = (GID_T)(get_global_id(0), get_global_id(1));
#endif


__kernel void intensity(__read_only IMG_T inputImage,
                        __write_only IMG_T outImage) {
  
  INIT_GID(gid)

  float4 f4 = (float4)read_imagef(inputImage, sampler, gid);

  float4 newf4 = (float4)(f4.x * 0.2126, f4.y * 0.7152, f4.z * 0.0722, f4.w);

  write_imagef(outImage, gid, f4);
}

#if 0

__kernel void getComponent(__read_only image_t inputImage,
                           __write_only image_t outputImage,
                           __global unsigned int *c,
                           __global unsigned int *dim) {

  uint4 ui4;
  int2 gid;
  int3 gid2;
  if (*dim == 2) {
    gid = (int2)(get_global_id(0), get_global_id(1));
    ui4 = read_imageui((image2d_t)inputImage, sampler, gid);
  } else {
    gid2 = (int3)(get_global_id(0), get_global_id(1), get_global_id(2));
    ui4 = read_imageui((__read_only image3d_t)inputImage, sampler, gid2);
  }

  int i = ((0 == *c) * ui4.x) + ((1 == *c) * ui4.y) + ((2 == *c) * ui4.z) +
          ((3 == *c) * ui4.w);

  if (*dim == 2)
    write_imageui((image2d_t)outputImage, gid, i);
  else
    write_imageui((__write_only image2d_t)outputImage, gid2, i);
}

__kernel void rgbComps(__read_only image_t inputImage1,
                       __read_only image_t inputImage2,
                       __read_only image_t inputImage3,
                       __write_only image_t outImage,
                       __global unsigned int *dim) {
  uint4 pix1;
  uint4 pix2;
  uint4 pix3;
  int2 gid;
  int3 gid2;

  if (*dim == 2) {
    gid = (int2)(get_global_id(0), get_global_id(1));
    pix1 = (uint4)read_imageui((image2d_t)inputImage1, gid);
    pix2 = (uint4)read_imageui((image2d_t)inputImage2, gid);
    pix3 = (uint4)read_imageui((image2d_t)inputImage3, gid);

  } else {
    gid2 = (int3)(get_global_id(0), get_global_id(1), get_global_id(2));
    pix1 = (uint4)read_imageui((__read_only image3d_t)inputImage1, gid2);
    pix2 = (uint4)read_imageui((__read_only image3d_t)inputImage2, gid2);
    pix3 = (uint4)read_imageui((__read_only image3d_t)inputImage3, gid2);
  }

  if (*dim == 2)
    write_imageui((image2d_t)outImage, gid,
                  (uint4)(pix1.x, pix2.y, pix3.z, 255));
  else
    write_imageui((__write_only image3d_t)outImage, gid2,
                  (uint4)(pix1.x, pix2.y, pix3.z, 255));
}

__kernel void
rgbaComps(__read_only image_t inputImage1, __read_only image_t inputImage2,
          __read_only image_t inputImage3, __read_only image_t inputImage4,
          __write_only image_t outImage, __global unsigned int *dim) {
  uint4 pix1;
  uint4 pix2;
  uint4 pix3;
  uint4 pix4;
  int2 gid;
  int3 gid2;

  if (*dim == 2) {
    gid = (int2)(get_global_id(0), get_global_id(1));
    pix1 = (uint4)read_imageui((image2d_t)inputImage1, gid);
    pix2 = (uint4)read_imageui((image2d_t)inputImage2, gid);
    pix3 = (uint4)read_imageui((image2d_t)inputImage3, gid);
    pix4 = (uint4)read_imageui((image2d_t)inputImage4, gid);
  } else {
    gid2 = (int3)(get_global_id(0), get_global_id(1), get_global_id(2));
    pix1 = (uint4)read_imageui((__read_only image3d_t)inputImage1, gid2);
    pix2 = (uint4)read_imageui((__read_only image3d_t)inputImage2, gid2);
    pix3 = (uint4)read_imageui((__read_only image3d_t)inputImage3, gid2);
    pix4 = (uint4)read_imageui((__read_only image3d_t)inputImage4, gid2);
  }

  if (*dim == 2)
    write_imageui((image2d_t)outImage, gid,
                  (uint4)(pix1.x, pix2.y, pix3.z, pix4.w));
  else
    write_imageui((__write_only image3d_t)outImage, gid2,
                  (uint4)(pix1.x, pix2.y, pix3.z, pix4.w));
}

__kernel void trueImg(__write_only image_t outputImage,
                      __global unsigned int *dim) {

  int2 gid;
  int3 gid2;
  if (*dim == 2) {
    gid = (int2)(get_global_id(0), get_global_id(1));
    write_imageui((image2d_t)outputImage, gid, 1);
  } else {
    gid = (int3)(get_global_id(0), get_global_id(1), get_global_id(2));
    write_imageui((__write_only image3d_t)outputImage, gid2, 1);
  }
}

__kernel void falseImg(__write_only image_t outputImage,
                       __global unsigned int *dim) {
  int2 gid;
  int3 gid2;
  if (*dim == 2) {
    int2 gid = (int2)(get_global_id(0), get_global_id(1));
    write_imageui((image2d_t)outputImage, gid, 0);
  } else {
    int3 gid = (int3)(get_global_id(0), get_global_id(1), get_global_id(2));
    write_imageui((__write_only image3d_t)outputImage, gid2, 0);
  }
}

/******************** TEST KERNELS ********************/

__kernel void swapRG(__read_only image2d_t inputImage,
                     __write_only image2d_t outImage) {
  int2 gid = (int2)(get_global_id(0), get_global_id(1));

  float4 f4 = (float4)read_imagef(inputImage, sampler, gid);
  float4 newf4 = (float4)(f4.y, f4.x, f4.z, f4.w);

  write_imagef(outImage, gid, newf4);
}

__kernel void test(__write_only image2d_t outImage) {
  int2 gid = (int2)(get_global_id(0), get_global_id(1));

  float4 newf4 = (float4)(255, 0, 0, 255);
  write_imagef(outImage, gid, newf4);
}

__kernel void slow(__read_only image2d_t inputImage,
                   __write_only image2d_t outImage) {
  int2 gid = (int2)(get_global_id(0), get_global_id(1));
  float4 f4 = (float4)read_imagef(inputImage, sampler, gid);
  float4 newf4 = (float4)(f4.x, f4.y, f4.z, f4.w);

  for (int i = 0; i < 1000; i++) {
    for (int j = 0; j < 3; j++)
      newf4[j] = fmod(newf4[j] * newf4[j], 251.0f);
  }

  write_imagef(outImage, gid, newf4);
}

#endif