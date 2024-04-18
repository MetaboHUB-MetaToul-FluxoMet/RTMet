from pathlib import Path
from datetime import datetime
import catch_raw

# Quels tests doit-on écrire pour get_raws_datetimes?
#   1. get_raws_datetimes retourne un dictionnaire de forme {Path: datetime}
#   2. get_raws_datetimes retourne un dictionnaire vide si aucun fichier .raw n'est présent
#   3. get_raws_datetimes retourne tous les fichiers .raw présents dans le répertoire
#   4. get_raws_datetimes ne retourne que les fichiers .raw
#   5. get_raws_datetimes ne retourne pas les répertoires
#   6. get_raws_datetimes ne retourne pas les fichiers .raw dans les sous-répertoires
# Quels tests doit-on écrire pour catch_raw?
#   6. catch_raw retourne un tuple (bool, dict)
#   7. catch_raw retourne un tuple (False, {}) si aucun fichier .raw n'est présent
#   8. catch_raw retourne un tuple (True, {Path: datetime}) si un fichier .raw est présent



class TestGetRawsDatetimes:
    """Tests pour la fonction get_raws_datetimes"""
    def test_returnsdict(self, tmp_path: Path):
        """get_raws_datetimes retourne un dictionnaire
        de forme {Path: datetime}
        """
        # Arrange
        # Créer un fichier .raw
        raw_file = tmp_path / "test.raw"
        raw_file.touch()
        # Act
        result = catch_raw.get_raws_datetimes(tmp_path)
        # Assert
        assert isinstance(result, dict)
        assert len(result) == 1
        assert raw_file in result
        assert isinstance(result[raw_file], datetime)
        for key, _ in result.items():
            assert isinstance(key, Path)

    def test_returnsdictempty(self, tmp_path: Path):
        """get_raws_datetimes retourne un dictionnaire vide
        si aucun fichier .raw n'est présent
        """
        # Arrange
        # Act
        result = catch_raw.get_raws_datetimes(tmp_path)
        # Assert
        assert isinstance(result, dict)
        assert len(result) == 0

    def test_returnsallraws(self, tmp_path: Path):
        """get_raws_datetimes retourne tous les fichiers .raw
        présents dans le répertoire
        """
        # Arrange
        # Créer des fichiers .raw
        raw_file1 = tmp_path / "test1.raw"
        raw_file1.touch()
        raw_file2 = tmp_path / "test2.raw"
        raw_file2.touch()
        # Act
        result = catch_raw.get_raws_datetimes(tmp_path)
        # Assert
        assert isinstance(result, dict)
        assert len(result) == 2
        assert raw_file1 in result
        assert raw_file2 in result

    def test_returnsonlyraws(self, tmp_path: Path):
        """get_raws_datetimes ne retourne que les fichiers .raw
        """
        # Arrange
        # Créer un fichier .raw
        raw_file = tmp_path / "test.raw"
        raw_file.touch()
        # Créer un fichier .txt
        txt_file = tmp_path / "test.txt"
        txt_file.touch()
        # Act
        result = catch_raw.get_raws_datetimes(tmp_path)
        # Assert
        assert isinstance(result, dict)
        assert len(result) == 1
        assert raw_file in result
        assert txt_file not in result

    def test_returnsnodirs(self, tmp_path: Path):
        """get_raws_datetimes ne retourne pas les répertoires
        """
        # Arrange
        # Créer un fichier .raw
        raw_file = tmp_path / "test.raw"
        raw_file.touch()
        # Créer un répertoire
        directory = tmp_path / "testdir"
        directory.mkdir()
        # Act
        result = catch_raw.get_raws_datetimes(tmp_path)
        # Assert
        assert isinstance(result, dict)
        assert len(result) == 1
        assert raw_file in result
        assert directory not in result
    
    def test_returnsnorawssubdirs(self, tmp_path: Path):
        """get_raws_datetimes ne retourne pas les fichiers .raw
        dans les sous-répertoires
        """
        # Arrange
        # Créer un fichier .raw
        raw_file = tmp_path / "test.raw"
        raw_file.touch()
        # Créer un sous-répertoire
        subdir = tmp_path / "subdir"
        subdir.mkdir()
        # Créer un fichier .raw dans le sous-répertoire
        raw_file_subdir = subdir / "test.raw"
        raw_file_subdir.touch()
        # Act
        result = catch_raw.get_raws_datetimes(tmp_path)
        # Assert
        assert isinstance(result, dict)
        assert len(result) == 1
        assert raw_file in result
        assert raw_file_subdir not in result

class TestCatchRaw:
    """Tests pour la fonction catch_raw"""
    def test_returnstuple(self):
        """catch_raw retourne un tuple (bool, dict)
        """
        # Arrange
        # Act
        result = catch_raw.catch_raw()
        # Assert
        assert isinstance(result, tuple)
        assert len(result) == 2
        assert isinstance(result[0], bool)
        assert isinstance(result[1], dict)