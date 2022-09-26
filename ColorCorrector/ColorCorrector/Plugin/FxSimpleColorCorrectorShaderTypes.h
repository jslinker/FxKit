//
//  FxSimpleColorCorrectorShaderTypes.h
//  PlugIn
//
//  Created by Apple on 10/4/18.
//  Copyright © 2019-2021 Apple Inc. All rights reserved.
//

#ifndef FxShapeShaderTypes_h
#define FxShapeShaderTypes_h

#import <simd/simd.h>

typedef enum FxSCCVertexInputIndex {
    SCC_Vertices = 0,
    SCC_ViewportSize = 1
} FxSCCVertexInputIndex;

typedef enum FxSCCTextureIndex {
    SCC_InputImage = 0,
} FxSCCTextureIndex;

typedef enum FxSCCBufferIndex {
    SCC_Color = 0
} FxSCCBufferIndex;

typedef struct Vertex2D {
    vector_float2   position;
    vector_float2   textureCoordinate;
} Vertex2D;

#endif /* FxShapeShaderTypes_h */
