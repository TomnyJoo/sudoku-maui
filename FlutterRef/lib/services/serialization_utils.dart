import 'dart:typed_data';
import 'package:sudoku/models/index.dart';

/// 序列化工具类
/// 提供高效的 Board 和相关对象的序列化/反序列化
class SerializationUtils {
  /// 序列化 Board 为二进制数据
  static Uint8List serializeBoard(Board board) {
    final size = board.size;
    
    final buffer = BytesBuilder();
    final writer = _ByteWriter(buffer) 
    // 写入棋盘大小
    ..writeInt32(size);
    
    // 写入单元格数据
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final cell = board.getCell(row, col);
        // 使用 2 字节存储单元格数据
        // 高 4 位: value (0-9, 0 表示空)
        // 低 1 位: isFixed (0 或 1)
        int cellData = cell.value ?? 0;
        if (cell.isFixed) {
          cellData |= 0x10; // 设置第 5 位
        }
        writer.writeUint16(cellData);
      }
    }
    
    // 写入区域数据
    writer.writeInt32(board.regions.length);
    for (final region in board.regions) {
      writer..writeString(region.id)
      ..writeInt32(region.cells.length);
      for (final cell in region.cells) {
        writer.writeUint16((cell.row << 8) | cell.col);
      }
    }
    
    return buffer.toBytes();
  }
  
  /// 从二进制数据反序列化 Board
  static Board deserializeBoard(Uint8List data, GameType gameType) {
    final reader = _ByteReader(data);
    
    // 读取棋盘大小
    final size = reader.readInt32();
    
    // 创建指定类型的空棋盘
    final Board emptyBoard;
    switch (gameType) {
      case GameType.standard:
        emptyBoard = StandardBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.diagonal:
        emptyBoard = DiagonalBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.window:
        emptyBoard = WindowBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.jigsaw:
        emptyBoard = JigsawBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.killer:
        emptyBoard = KillerBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.samurai:
        emptyBoard = SamuraiBoard(cells: Board.createEmptyCells(size));
    }
    final board = emptyBoard;
    
    var workingBoard = board;
    
    // 读取单元格数据
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final cellData = reader.readUint16();
        final value = (cellData & 0x0F) == 0 ? null : (cellData & 0x0F);
        final isFixed = (cellData & 0x10) != 0;

        if (value != null || isFixed) {
          final cell = workingBoard.getCell(row, col);
          final newCell = cell.copyWith(
            value: value ?? cell.value,
            isFixed: isFixed,
          );
          workingBoard = workingBoard.setCell(row, col, newCell);
        }
      }
    }

    // 读取区域数据并重建
    final regionCount = reader.readInt32();
    final newRegions = <Region>[];
    for (int i = 0; i < regionCount; i++) {
      final regionId = reader.readString();
      final cellCount = reader.readInt32();
      final regionCells = <Cell>[];
      for (int j = 0; j < cellCount; j++) {
        final cellCoord = reader.readUint16();
        final cellRow = (cellCoord >> 8) & 0xFF;
        final cellCol = cellCoord & 0xFF;
        regionCells.add(workingBoard.getCell(cellRow, cellCol));
      }
      newRegions.add(Region(
        id: regionId,
        type: RegionType.custom,
        name: regionId,
        cells: regionCells,
      ));
    }

    // 如果有区域数据，使用带区域的cells重建Board
    if (newRegions.isNotEmpty) {
      workingBoard = workingBoard.copyWith(regions: newRegions);
    }

    return workingBoard;
  }
  
  /// 序列化 Board 为 JSON (优化版本)
  static Map<String, dynamic> boardToJson(Board board) {
    final size = board.size;
    final cells = <Map<String, dynamic>>[];
    
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final cell = board.getCell(row, col);
        cells.add({
          'r': row,
          'c': col,
          'v': cell.value,
          'f': cell.isFixed,
          'cd': cell.candidates.toList(),
        });
      }
    }
    
    final regions = board.regions.map((region) => {
        'id': region.id,
        'cells': region.cells.map((cell) => {'r': cell.row, 'c': cell.col}).toList(),
      }).toList();
    
    return {
      'size': size,
      'cells': cells,
      'regions': regions,
    };
  }
  
  /// 从 JSON 反序列化 Board (优化版本)
  static Board boardFromJson(Map<String, dynamic> json, GameType gameType) {
    final size = json['size'] as int;
    final cellsJson = (json['cells'] as List).cast<Map<String, dynamic>>();
    
    // 创建指定类型的空棋盘
    final Board emptyBoard;
    switch (gameType) {
      case GameType.standard:
        emptyBoard = StandardBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.diagonal:
        emptyBoard = DiagonalBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.window:
        emptyBoard = WindowBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.jigsaw:
        emptyBoard = JigsawBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.killer:
        emptyBoard = KillerBoard(size: size, cells: Board.createEmptyCells(size));
      case GameType.samurai:
        emptyBoard = SamuraiBoard(cells: Board.createEmptyCells(size));
    }
    final board = emptyBoard;
    
    var workingBoard = board;
    
    // 填充单元格数据
    for (final cellJson in cellsJson) {
      final row = cellJson['r'] as int;
      final col = cellJson['c'] as int;
      final value = cellJson['v'] as int?;
      final isFixed = cellJson['f'] as bool? ?? false;
      final candidates = (cellJson['cd'] as List?)?.cast<int>().toSet();

      // 使用Board的方法更新单元格（包括固定状态）
      if (value != null || isFixed) {
        final cell = workingBoard.getCell(row, col);
        final newCell = cell.copyWith(
          value: value ?? cell.value,
          isFixed: isFixed,
        );
        workingBoard = workingBoard.setCell(row, col, newCell);
      }
      if (candidates != null && candidates.isNotEmpty) {
        workingBoard = workingBoard.setCellCandidates(row, col, candidates);
      }
    }

    // 读取区域数据
    final regionsJson = json['regions'] as List?;
    if (regionsJson != null && regionsJson.isNotEmpty) {
      final newRegions = <Region>[];
      for (final regionJson in regionsJson) {
        final regionMap = regionJson as Map<String, dynamic>;
        final regionCells = (regionMap['cells'] as List).map((cellJson) {
          final cellMap = cellJson as Map<String, dynamic>;
          return workingBoard.getCell(cellMap['r'] as int, cellMap['c'] as int);
        }).toList();
        newRegions.add(Region(
          id: regionMap['id'] as String,
          type: RegionType.custom,
          name: regionMap['id'] as String,
          cells: regionCells,
        ));
      }
      workingBoard = workingBoard.copyWith(regions: newRegions);
    }

    return workingBoard;
  }
}

/// 字节写入器
class _ByteWriter {
  
  _ByteWriter(this._builder);
  final BytesBuilder _builder;
  
  void writeInt32(int value) {
    final bytes = ByteData(4)..setInt32(0, value, Endian.little);
    _builder.add(bytes.buffer.asUint8List());
  }
  
  void writeUint16(int value) {
    final bytes = ByteData(2)..setUint16(0, value, Endian.little);
    _builder.add(bytes.buffer.asUint8List());
  }
  
  void writeString(String value) {
    writeInt32(value.length);
    _builder.add(value.codeUnits);
  }
}

/// 字节读取器
class _ByteReader {
  
  _ByteReader(this._data);
  final Uint8List _data;
  int _position = 0;
  
  int readInt32() {
    final value = ByteData.sublistView(_data, _position, _position + 4).getInt32(0, Endian.little);
    _position += 4;
    return value;
  }
  
  int readUint16() {
    final value = ByteData.sublistView(_data, _position, _position + 2).getUint16(0, Endian.little);
    _position += 2;
    return value;
  }
  
  String readString() {
    final length = readInt32();
    final value = String.fromCharCodes(_data.sublist(_position, _position + length));
    _position += length;
    return value;
  }
}
