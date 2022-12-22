import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

class InstaAssetsExportDetails {
  final List<InstaAssetsCrop> cropParamsList;
  final List<File> croppedFiles;
  final double aspectRatio;

  const InstaAssetsExportDetails({
    required this.cropParamsList,
    required this.croppedFiles,
    required this.aspectRatio,
  });
}

class InstaAssetsCrop {
  final AssetEntity asset;
  final CropInternal? cropParam;

  // export crop params
  final double scale;
  final Rect? area;

  const InstaAssetsCrop({
    required this.asset,
    required this.cropParam,
    this.scale = 1.0,
    this.area,
  });

  static InstaAssetsCrop fromState({
    required AssetEntity asset,
    required CropState? cropState,
  }) {
    return InstaAssetsCrop(
      asset: asset,
      cropParam: cropState?.internalParameters,
      scale: cropState?.scale ?? 1.0,
      area: cropState?.area,
    );
  }

  InstaAssetsCrop copyWith({AssetEntity? asset, CropState? cropState}) {
    return InstaAssetsCrop(
      asset: asset ?? this.asset,
      cropParam: cropState?.internalParameters ?? cropParam,
      scale: cropState?.scale ?? scale,
      area: cropState?.area ?? area,
    );
  }
}

class InstaAssetsCropController {
  InstaAssetsCropController(List<InstaAssetsCrop>? initialList)
      : list = initialList ?? [];

  List<InstaAssetsCrop> list;
  final ValueNotifier<bool> isCropViewReady = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSquare = ValueNotifier<bool>(true);
  final ValueNotifier<AssetEntity?> previewAsset =
      ValueNotifier<AssetEntity?>(null);

  dispose() {
    isCropViewReady.dispose();
    isSquare.dispose();
    previewAsset.dispose();
  }

  double get aspectRatio => isSquare.value ? 1 : 4 / 5;

  void clear() {
    list = [];
    previewAsset.value = null;
  }

  void onChange(
    AssetEntity? saveAsset,
    CropState? saveCropState,
    List<AssetEntity> selectedAssets,
  ) {
    final List<InstaAssetsCrop> newList = [];

    for (final asset in selectedAssets) {
      final savedCropAsset = get(asset);

      if (asset == saveAsset && saveAsset != null) {
        newList.add(InstaAssetsCrop.fromState(
          asset: saveAsset,
          cropState: saveCropState,
        ));
      } else if (savedCropAsset == null) {
        newList.add(InstaAssetsCrop.fromState(asset: asset, cropState: null));
      } else {
        newList.add(savedCropAsset);
      }
    }

    list = newList;
  }

  InstaAssetsCrop? get(AssetEntity asset) {
    if (list.isEmpty) return null;
    final index = list.indexWhere((e) => e.asset == asset);
    if (index == -1) return null;
    return list[index];
  }

  Future<InstaAssetsExportDetails> exportCropFiles({
    required Function(double) onProgress,
  }) async {
    List<File> croppedFiles = [];
    final step = 1 / list.length;
    onProgress(0);

    for (var i = 0; i < list.length; i++) {
      final file = await list[i].asset.file;

      final scale = list[i].scale;
      final area = list[i].area;

      if (file == null) {
        throw 'error file is null';
      }

      if (area == null) {
        croppedFiles.add(file);
        break;
      }

      final sampledFile = await ImageCrop.sampleImage(
        file: file,
        preferredSize: (1024 / scale).round(),
      );

      final croppedFile =
          await ImageCrop.cropImage(file: sampledFile, area: area);

      onProgress((i + 1) * step);
      croppedFiles.add(croppedFile);
    }

    return InstaAssetsExportDetails(
      cropParamsList: list,
      croppedFiles: croppedFiles,
      aspectRatio: aspectRatio,
    );
  }
}
