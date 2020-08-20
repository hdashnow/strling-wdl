workflow SimpleVariantDiscovery {

  meta {
      author: "Harriet Dashnow"
      email: "h.dashnow@gmail.com"
      description: "Run STRling (github.com/quinlan-lab/STRling) in individual calling mode to detect and genotype STRs"
  }

  # Columns from the sample_set
  Array[String] sample
  Array[String] bam
  Array[String] bam_index

  File ref_fasta
  File ref_str

  scatter (sample_col in sample_data) {

    call str_extract {
      input:
        ref_fasta = ref_fasta,
        ref_str = ref_str,

        sample = sample,
        bam = bam,
        bam_index = bam_index,
    }

     call str_call_individual {
      input:
        ref_fasta = ref_fasta,
        ref_str = ref_str,
        bin = str_extract.bin,

        sample = sample,
        bam = bam,
        bam_index = bam_index,
    }

  }

}

task str_extract {
  File ref_fasta
  File ref_str
  String sample
  File bam
  File bam_index

  command {
    strling extract \
      -f ${ref_fasta} \
      -g ${ref_str} \
      ${bam} \
      ${sample}.bin
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "hdashnow/strling:latest"
  }
  output {
    File bin = "${sample}.bin"
  }
}

task str_call_individual {
  File ref_fasta
  File ref_str
  String sample
  File bam
  File bam_index
  File bin

  command {
    strling call \
      -f ${ref_fasta} \
      -o ${sample} \
      ${bam} \
      ${bin}
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "hdashnow/strling:latest"
  }
  output {
    File output_bounds = "${sample}-bounds.txt"
    File output_unplaced = "${sample}-unplaced.txt"
    File output_genotype = "${sample}-genotype.txt"
  }
}

