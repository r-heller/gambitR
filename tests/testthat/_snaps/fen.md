# malformed FEN is rejected with an informative message

    Code
      gm_read_fen(42)
    Condition
      Error:
      ! `fen` must be a single non-NA string.
    Code
      gm_read_fen("not a fen")
    Condition
      Error:
      ! `fen` must have between four and six space-separated fields.
      x "not a fen" has 3.
    Code
      gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP w KQkq - 0 1")
    Condition
      Error:
      ! The piece placement field must have eight ranks separated by "/".
      x "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP" has 7.
    Code
      gm_read_fen("rnbqkbnr/ppppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    Condition
      Error:
      ! Every rank of the piece placement field must describe eight squares.
      x Rank 7 ("ppppppppp") describes 9.
    Code
      gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR x KQkq - 0 1")
    Condition
      Error:
      ! The side to move must be "w" or "b".
      x Got "x".
    Code
      gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQXq - 0 1")
    Condition
      Error:
      ! Castling availability must be "-" or a subset of "KQkq".
      x Got "KQXq".
    Code
      gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq e4 0 1")
    Condition
      Error:
      ! The en passant target must be "-" or a square on rank 3 or 6.
      x Got "e4".
    Code
      gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - x 1")
    Condition
      Error:
      ! The halfmove clock must be a non-negative whole number.
      x Got "x".
    Code
      gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0")
    Condition
      Error:
      ! The fullmove number must be at least 1, not 0.

