static void sigmoid_TTL_optimized(float v1[64][128], float v2[64][128]) {
  double v3 = 1.00000000000000000e+00;
  size_t v4 = 0;
  size_t v5 = 64;
  size_t v6 = 4;
  for (size_t v7 = v4; v7 < v5; v7 += v6) {
    size_t v8 = 0;
    size_t v9 = 128;
    size_t v10 = 4;
    for (size_t v11 = v8; v11 < v9; v11 += v10) {
      size_t v12 = 4;
      size_t v13 = v7 + v12;
      size_t v14 = 1;
      for (size_t v15 = v7; v15 < v13; v15 += v14) {
        size_t v16 = 4;
        size_t v17 = v11 + v16;
        size_t v18 = 1;
        for (size_t v19 = v11; v19 < v17; v19 += v18) {
          float v20 = v1[v15][v19];
          float v21 = -v20;
          double v22 = (double) v21;
          double v23 = exp(v22);
          double v24 = v23 + v3;
          double v25 = v3 / v24;
          float v26 = (float) v25;
          v2[v15][v19] = v26;
        }
      }
    }
  }
  return;
}


