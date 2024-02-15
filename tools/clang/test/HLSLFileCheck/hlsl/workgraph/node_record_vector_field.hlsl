// RUN: %dxc -T lib_6_8 %s
// ==================================================================
// Vector fields within node records were sometimes causing DXC to
// crash - we check that these cases now compile
// ==================================================================

// CHECK: define void @Entry()

static const int maxPoints = 8;

struct EntryRecord {
    float2 points[maxPoints];
    int    pointCoint;
};

[Shader("node")]
[NodeIsProgramEntry]
[NodeLaunch("broadcasting")]
[NodeDispatchGrid(1, 1, 1)]
[NumThreads(32, 1, 1)]
void Entry(uint gtid : SV_GroupThreadId,
           DispatchNodeInputRecord<EntryRecord> inputData)
{
  EntryRecord input = inputData.Get();

  if (gtid < input.pointCoint) {
    // reading input.points[0] worked, but a variable index failed
    float2 p = input.points[gtid];
  }

  [[unroll]]
  for (int i = 0; i < 8; ++i) {
    float2 p = input.points[i];
  }
}

//========================================

// CHECK: define void @secondNode() {

struct innerRecord
{
  uint a;
  uint2 entryRecordIndex;
};

struct outputRecord
{
  innerRecord x;
};

[Shader("node")]
[NodeLaunch("thread")]
void secondNode([MaxRecords(1)] NodeOutput<outputRecord> output)
{
  ThreadNodeOutputRecords<outputRecord> outRec = output.GetThreadNodeOutputRecords(1);
  outputRecord o = {0, uint2(0,0)};
  outRec.Get().x = o.x;
  outRec.OutputComplete();
}
