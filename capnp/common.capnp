@0xd7b1fdae7f8daa87;

# Both task and data object id share the same numbering space and must use distinct ids.
# Session id is assigned by the server. Objects from different sessions may not interact.
# Session id <0 has a special meaning.
# Task id and data object id are the same struct but are distinct types for type checking.

using SessionId = Int32;

const allTasksId :Int32 = -2;
const allDataObjectsId :Int32 = -2;

struct TaskId {
    id @0 :Int32;
    sessionId @1 :SessionId;

    const none :TaskId = ( sessionId = -1, id = 0 );
}

struct DataObjectId {
    id @0 :Int32;
    sessionId @1 :SessionId;

    const none :DataObjectId = ( sessionId = -1, id = 0 );
}

struct SocketAddress {
    # IPv4/6 address of a socket.
    port @0 :UInt16;
    address :union {
        ipv4 @1: Data; # Network-endian address (4 bytes)
        ipv6 @2: Data; # Network-endian address (16 bytes)
    }
}

using WorkerId = SocketAddress;
# Worker id is the address of the RPC listening port.

enum TaskState {
        notAssigned @0;
        assigned @1;
        ready @2;
        running @3;
        finished @4;
}

enum DataObjectState {
    notAssigned @0;
    assigned @1;
    running @2;
    finished @3;
    removed @4;
}

struct Additional {
    # Additonal data - stats, plugin data, user data, ...
    # TODO: Specify in an extensible way.
    # TODO: Consider embedding CBOR, MSGPACK, ... as Data.

    items @0 :List(Item);

    struct Item {
        key @0 :Text;
        value :union {
            int @1 :Int64;
            float @2 :Float64;
            text @3 :Text;
            data @4 :Data;
        }
    }
}

struct Resources {
    nCpus @0 : UInt32;
}