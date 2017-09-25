use std::io::Read;
use std::path::{PathBuf, Path};
use std::os::unix::fs::PermissionsExt;

use errors::Result;

pub struct DataOnFs {
    pub path: PathBuf,
    /// If data is directory than size is sum of sizes of all blobs in directory
    pub size: usize
}

pub enum Storage {
    Memory(Vec<u8>),
    Path(DataOnFs)
}

#[derive(Copy, Clone)]
pub enum DataType {
    Blob,
    Directory,
    Stream
}

pub struct Data {
    data_type: DataType,
    storage: Storage,
}


impl Data {

    /// Create Data from vector
    pub fn new(data_type: DataType, storage: Storage) -> Data {
        Data {
            data_type, storage
        }
    }

    pub fn new_from_path(data_type: DataType, path: PathBuf, size: usize) -> Data {
        Data {
            data_type,
            storage: Storage::Path(DataOnFs {path, size})
        }
    }

    pub fn new_by_fs_move(source_path: &Path, target_path: PathBuf) -> ::std::result::Result<Self, ::std::io::Error> {
        ::std::fs::rename(source_path, &target_path)?;
        let metadata = ::std::fs::metadata(&target_path)?;
        metadata.permissions().set_mode(0o400);
        let size = metadata.len() as usize;
        Ok(Data::new_from_path(DataType::Blob, target_path, size))
    }

    pub fn storage(&self) -> &Storage {
        &self.storage
    }

    pub fn data_type(&self) -> DataType {
        self.data_type
    }

    pub fn from_file(data_type: DataType, path: &Path) -> Data {
        unimplemented!()
    }

    /// Return size of data in bytes
    /// If data is directory than size is sum of sizes of all blobs in directory
    pub fn size(&self) -> usize {
        match self.storage {
            Storage::Memory(ref data) => data.len(),
            Storage::Path(ref data) => data.size
        }
    }

    /// Map data object on a given path
    /// Caller is responsible for deletion of the path
    /// It creates a symlink to real data or new file if data only in memory
    pub fn map_to_path(&self, path: &Path) -> Result<()> {
        use std::io::Write;
        use std::os::unix::fs::symlink;

        match self.storage {
            Storage::Memory(ref data) => {
                let mut file = ::std::fs::File::create(path)?;
                file.write_all(data)?;
            }
            Storage::Path(ref data) => {
                symlink(&data.path, path)?;
            }
        };
        Ok(())
    }

    #[inline]
    pub fn is_blob(&self) -> bool {
        match self.data_type {
            DataType::Blob => true,
            _ => false
        }
    }

}

impl Drop for Data {

    fn drop(&mut self) {
        match self.storage {
            Storage::Path(_) => unimplemented!(),
            Storage::Memory(_) => { /* Do nothing */ }
        }
    }
}